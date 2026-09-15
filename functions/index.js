/// Cloud Functions for Rambu Shogi Highlight Video Generation
/// Video encoding, progress tracking, and job management

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const ffmpeg = require('fluent-ffmpeg');
const path = require('path');
const os = require('os');
const fs = require('fs');

// Initialize Firebase Admin SDK
admin.initializeApp();

const bucket = admin.storage().bucket('rambu-highlights');
const db = admin.firestore();

// In-memory job tracker (for single-region deployment)
// In production, use Firestore for distributed tracking
const jobTracker = new Map();

// Utility: Generate unique job ID
function generateJobId() {
  return 'job_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
}

// Utility: Update job status in tracker
function updateJobStatus(jobId, status, percentComplete = 0, errorMessage = null) {
  jobTracker.set(jobId, {
    jobId,
    status,      // 'pending', 'encoding', 'completed', 'failed'
    percentComplete,
    errorMessage,
    timestamp: new Date().toISOString(),
  });

  console.log(`[${jobId}] Status: ${status} (${percentComplete}%)`);
}

// Utility: Get FFmpeg path (or use system ffmpeg)
function getFfmpegPath() {
  // In Cloud Functions environment, ffmpeg should be available
  // If not, use explicit path: '/opt/ffmpeg/bin/ffmpeg'
  return 'ffmpeg';
}

/**
 * HTTP Cloud Function: Start video encoding job
 *
 * Request body:
 * {
 *   "imageSequencePath": "gs://bucket/frames/frame_%06d.png",
 *   "outputPath": "gs://bucket/videos/output.mp4",
 *   "frameRate": 30,
 *   "durationSeconds": 15,
 *   "videoCodec": "h264",
 *   "bitrate": 2000
 * }
 *
 * Response: { "jobId": "job_...", "status": "pending" }
 */
exports.encodeHighlightVideo = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    try {
      const {
        imageSequencePath,
        outputPath,
        frameRate = 30,
        durationSeconds = 15,
        videoCodec = 'h264',
        bitrate = 2000,
      } = data;

      // Validate input
      if (!imageSequencePath || !outputPath) {
        throw new Error('Missing required parameters: imageSequencePath, outputPath');
      }

      const jobId = generateJobId();

      // Initialize job status
      updateJobStatus(jobId, 'pending', 0);

      // Start encoding asynchronously (don't wait for completion)
      performEncoding(jobId, {
        imageSequencePath,
        outputPath,
        frameRate,
        durationSeconds,
        videoCodec,
        bitrate,
      }).catch(error => {
        updateJobStatus(jobId, 'failed', 0, error.message);
      });

      return {
        jobId,
        status: 'pending',
        message: 'Video encoding started',
      };
    } catch (error) {
      console.error('Error starting video encoding:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * HTTP Cloud Function: Check encoding progress
 *
 * Request body:
 * {
 *   "jobId": "job_..."
 * }
 *
 * Response: { "jobId": "...", "status": "encoding", "percentComplete": 45 }
 */
exports.checkEncodeProgress = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    try {
      const { jobId } = data;

      if (!jobId) {
        throw new Error('Missing required parameter: jobId');
      }

      const jobStatus = jobTracker.get(jobId);

      if (!jobStatus) {
        throw new Error(`Job not found: ${jobId}`);
      }

      return jobStatus;
    } catch (error) {
      console.error('Error checking progress:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * HTTP Cloud Function: Cancel encoding job
 *
 * Request body:
 * {
 *   "jobId": "job_..."
 * }
 *
 * Response: { "jobId": "...", "status": "cancelled" }
 */
exports.cancelEncoding = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    try {
      const { jobId } = data;

      if (!jobId) {
        throw new Error('Missing required parameter: jobId');
      }

      const jobStatus = jobTracker.get(jobId);

      if (!jobStatus) {
        throw new Error(`Job not found: ${jobId}`);
      }

      if (jobStatus.status === 'completed' || jobStatus.status === 'failed' || jobStatus.status === 'cancelled') {
        throw new Error(`Cannot cancel job with status: ${jobStatus.status}`);
      }

      updateJobStatus(jobId, 'cancelled', jobStatus.percentComplete, 'Cancelled by user');

      return {
        jobId,
        status: 'cancelled',
        message: 'Video encoding cancelled',
      };
    } catch (error) {
      console.error('Error cancelling encoding:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Internal: Perform actual video encoding
 *
 * This runs asynchronously and updates job status as it progresses
 */
async function performEncoding(jobId, options) {
  const {
    imageSequencePath,
    outputPath,
    frameRate,
    durationSeconds,
    videoCodec,
    bitrate,
  } = options;

  const tempDir = path.join(os.tmpdir(), `rambu-encode-${jobId}`);
  const inputPattern = path.join(tempDir, 'input_%06d.png');
  const tempOutputPath = path.join(tempDir, 'output.mp4');

  try {
    // Create temp directory
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    updateJobStatus(jobId, 'encoding', 5, null);

    // Download frame sequence from Cloud Storage
    console.log(`[${jobId}] Downloading frame sequence...`);
    await downloadFrameSequence(imageSequencePath, tempDir, jobId);

    updateJobStatus(jobId, 'encoding', 20, null);

    // Perform FFmpeg encoding
    console.log(`[${jobId}] Starting FFmpeg encoding...`);
    await encodeWithFFmpeg(
      inputPattern,
      tempOutputPath,
      frameRate,
      durationSeconds,
      videoCodec,
      bitrate,
      jobId
    );

    updateJobStatus(jobId, 'encoding', 80, null);

    // Upload encoded video to Cloud Storage
    console.log(`[${jobId}] Uploading encoded video...`);
    await uploadToCloudStorage(tempOutputPath, outputPath, jobId);

    updateJobStatus(jobId, 'completed', 100, null);

    console.log(`[${jobId}] ✅ Encoding completed successfully`);

  } catch (error) {
    console.error(`[${jobId}] ❌ Encoding failed:`, error);
    updateJobStatus(jobId, 'failed', 0, error.message);
    throw error;

  } finally {
    // Cleanup temp directory
    try {
      if (fs.existsSync(tempDir)) {
        fs.rmSync(tempDir, { recursive: true, force: true });
        console.log(`[${jobId}] Cleaned up temp directory`);
      }
    } catch (cleanupError) {
      console.warn(`[${jobId}] Warning: Failed to cleanup temp dir:`, cleanupError);
    }
  }
}

/**
 * Download frame sequence from Cloud Storage
 */
async function downloadFrameSequence(gsPath, localDir, jobId) {
  try {
    // Parse gs:// path
    // Example: gs://bucket-name/path/to/frames/frame_%06d.png
    const match = gsPath.match(/gs:\/\/([^/]+)\/(.+)/);
    if (!match) {
      throw new Error(`Invalid GCS path: ${gsPath}`);
    }

    const bucketName = match[1];
    const objectPrefix = match[2].replace(/frame_%06d\.png$/, 'frame_');

    const storageBucket = admin.storage().bucket(bucketName);
    const [files] = await storageBucket.getFiles({ prefix: objectPrefix });

    console.log(`[${jobId}] Found ${files.length} frame files to download`);

    // Download first 450 frames (15 seconds × 30 fps)
    const maxFrames = 450;
    let downloadedCount = 0;

    for (const file of files.slice(0, maxFrames)) {
      const fileName = path.basename(file.name);
      const localPath = path.join(localDir, fileName);

      await file.download({ destination: localPath });
      downloadedCount++;

      // Report progress every 50 frames
      if (downloadedCount % 50 === 0) {
        const progress = Math.floor((downloadedCount / files.length) * 10) + 5;
        updateJobStatus(jobId, 'encoding', progress, null);
      }
    }

    console.log(`[${jobId}] Downloaded ${downloadedCount} frames`);

  } catch (error) {
    throw new Error(`Failed to download frame sequence: ${error.message}`);
  }
}

/**
 * Encode frames to MP4 using FFmpeg
 */
async function encodeWithFFmpeg(
  inputPattern,
  outputPath,
  frameRate,
  durationSeconds,
  videoCodec,
  bitrate,
  jobId
) {
  return new Promise((resolve, reject) => {
    const ffmpegCmd = ffmpeg(inputPattern);

    ffmpegCmd
      .inputOptions([
        `-framerate ${frameRate}`,
        `-pattern_type glob`,
      ])
      .outputOptions([
        `-c:v ${videoCodec}`,
        `-b:v ${bitrate}k`,
        `-pix_fmt yuv420p`,
        `-movflags +faststart`,
        `-t ${durationSeconds}`,
      ])
      .on('start', (cmd) => {
        console.log(`[${jobId}] FFmpeg command: ${cmd}`);
      })
      .on('progress', (progress) => {
        // progress.percent ranges from 0-100
        const overallProgress = 20 + Math.min(progress.percent * 0.6, 60);
        updateJobStatus(jobId, 'encoding', Math.floor(overallProgress), null);
      })
      .on('error', (err) => {
        console.error(`[${jobId}] FFmpeg error:`, err);
        reject(new Error(`FFmpeg encoding failed: ${err.message}`));
      })
      .on('end', () => {
        console.log(`[${jobId}] FFmpeg encoding completed`);
        resolve();
      })
      .save(outputPath);
  });
}

/**
 * Upload encoded video to Cloud Storage
 */
async function uploadToCloudStorage(localPath, gsPath, jobId) {
  try {
    // Parse gs:// path
    const match = gsPath.match(/gs:\/\/([^/]+)\/(.+)/);
    if (!match) {
      throw new Error(`Invalid GCS path: ${gsPath}`);
    }

    const bucketName = match[1];
    const objectPath = match[2];

    const storageBucket = admin.storage().bucket(bucketName);

    console.log(`[${jobId}] Uploading to gs://${bucketName}/${objectPath}`);

    await storageBucket.upload(localPath, {
      destination: objectPath,
      metadata: {
        contentType: 'video/mp4',
        metadata: {
          jobId,
          encodedAt: new Date().toISOString(),
        },
      },
    });

    console.log(`[${jobId}] Upload completed`);

  } catch (error) {
    throw new Error(`Failed to upload video: ${error.message}`);
  }
}

/**
 * Scheduled function to clean up old jobs from memory
 * Runs every 1 hour to prevent memory leak in long-running functions
 */
exports.cleanupOldJobs = functions
  .region('asia-northeast1')
  .pubsub.schedule('every 60 minutes')
  .onRun((context) => {
    const now = Date.now();
    const oneHourAgo = now - (60 * 60 * 1000);
    let removedCount = 0;

    for (const [jobId, status] of jobTracker.entries()) {
      const jobTime = new Date(status.timestamp).getTime();
      if (jobTime < oneHourAgo && (status.status === 'completed' || status.status === 'failed')) {
        jobTracker.delete(jobId);
        removedCount++;
      }
    }

    console.log(`Cleanup: Removed ${removedCount} old jobs from memory`);
    console.log(`Remaining jobs in memory: ${jobTracker.size}`);

    return null;
  });

/**
 * Scheduled function for production deployment
 * For production, consider using Firestore for distributed job tracking
 */
exports.ensureHighlightBucket = functions
  .region('asia-northeast1')
  .pubsub.schedule('every day 03:00')
  .onRun(async (context) => {
    try {
      // Verify bucket exists
      const [exists] = await bucket.exists();
      if (!exists) {
        console.error('❌ Highlight bucket does not exist!');
        return;
      }

      console.log('✅ Highlight bucket verified');

      // Apply lifecycle rules
      const lifecycle = {
        rule: [
          {
            action: { type: 'Delete' },
            condition: {
              age: 30,
              matchesPrefix: ['videos/', 'thumbnails/'],
            },
          },
        ],
      };

      console.log('ℹ️  Lifecycle rules should be configured via gsutil or Terraform');
      console.log('Set via: gsutil lifecycle set lifecycle.json gs://rambu-highlights/');

    } catch (error) {
      console.error('Error in bucket verification:', error);
    }

    return null;
  });
