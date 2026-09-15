/// Audio Manager
/// BGM・SE・ボイスの一元管理

import 'package:rambu_shogi/models/story.dart';

/// オーディオ チャンネル
enum AudioChannel {
  bgm,      // BGM
  se,       // SE
  voice,    // ボイス
  ambient,  // 環境音
}

/// オーディオ状態
enum AudioState {
  stopped,
  playing,
  paused,
}

/// オーディオ トラック再生状態
class AudioTrackState {
  final AudioTrack track;
  final AudioState state;
  final double volume;
  final bool isLooping;
  final int? duration;

  AudioTrackState({
    required this.track,
    required this.state,
    required this.volume,
    required this.isLooping,
    this.duration,
  });
}

/// Audio Manager
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();

  /// 再生中のトラック
  final Map<AudioChannel, AudioTrackState?> _playingTracks = {};

  /// 各チャンネルの音量（0-1）
  final Map<AudioChannel, double> _volumes = {
    AudioChannel.bgm: 0.7,
    AudioChannel.se: 0.8,
    AudioChannel.voice: 0.9,
    AudioChannel.ambient: 0.5,
  };

  /// マスター音量
  double _masterVolume = 1.0;

  /// 初期化フラグ
  bool _initialized = false;

  AudioManager._internal();

  factory AudioManager() {
    return _instance;
  }

  /// 初期化
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // 実装: オーディオシステムの初期化
  }

  /// BGMを再生
  Future<void> playBGM(AudioTrack bgm, {double volume = 0.7}) async {
    await stopBGM();
    _playingTracks[AudioChannel.bgm] = AudioTrackState(
      track: bgm,
      state: AudioState.playing,
      volume: volume,
      isLooping: true,
      duration: null,
    );
  }

  /// BGMを停止
  Future<void> stopBGM({Duration? fadeDuration}) async {
    _playingTracks[AudioChannel.bgm] = null;
  }

  /// SEを再生
  Future<void> playSE(AudioTrack se, {double volume = 0.8}) async {
    _playingTracks[AudioChannel.se] = AudioTrackState(
      track: se,
      state: AudioState.playing,
      volume: volume,
      isLooping: false,
      duration: null,
    );
  }

  /// ボイスを再生
  Future<void> playVoice(String voiceUrl, {double volume = 0.9}) async {
    final track = AudioTrack(
      name: 'voice',
      filePath: voiceUrl,
      duration: 0,
    );
    _playingTracks[AudioChannel.voice] = AudioTrackState(
      track: track,
      state: AudioState.playing,
      volume: volume,
      isLooping: false,
      duration: null,
    );
  }

  /// チャンネルの音量を設定
  void setChannelVolume(AudioChannel channel, double volume) {
    _volumes[channel] = volume.clamp(0.0, 1.0);
    _updateChannelVolume(channel);
  }

  /// 各チャンネルの音量を更新
  void _updateChannelVolume(AudioChannel channel) {
    final state = _playingTracks[channel];
    if (state != null) {
      final effectiveVolume = state.volume * _volumes[channel]! * _masterVolume;
      // 実装: オーディオシステムに音量を設定
    }
  }

  /// マスター音量を設定
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    for (final channel in AudioChannel.values) {
      _updateChannelVolume(channel);
    }
  }

  /// 全てを停止
  Future<void> stopAll() async {
    _playingTracks.clear();
  }

  /// 再生状態を取得
  AudioTrackState? getPlayingTrack(AudioChannel channel) {
    return _playingTracks[channel];
  }

  /// チャンネルの音量を取得
  double getChannelVolume(AudioChannel channel) {
    return _volumes[channel] ?? 0.5;
  }

  /// マスター音量を取得
  double getMasterVolume() => _masterVolume;

  /// デバッグ出力
  void debugPrint() {
    print('=== Audio Manager State ===');
    print('Master Volume: ${(_masterVolume * 100).toStringAsFixed(0)}%');
    for (final channel in AudioChannel.values) {
      print('$channel Volume: ${(getChannelVolume(channel) * 100).toStringAsFixed(0)}%');
      print('$channel Playing: ${getPlayingTrack(channel)?.track.name ?? "None"}');
    }
  }
}

/// オーディオ マネージャー（Singleton）
class AudioManagerService {
  static final AudioManagerService _instance = AudioManagerService._internal();

  late AudioManager _manager;

  AudioManagerService._internal();

  factory AudioManagerService() {
    return _instance;
  }

  /// 初期化
  Future<void> initialize() async {
    _manager = AudioManager();
    await _manager.initialize();
  }

  /// BGMを再生
  Future<void> playBGM(AudioTrack bgm) => _manager.playBGM(bgm);

  /// BGMを停止
  Future<void> stopBGM() => _manager.stopBGM();

  /// SEを再生
  Future<void> playSE(AudioTrack se) => _manager.playSE(se);

  /// ボイスを再生
  Future<void> playVoice(String voiceUrl) => _manager.playVoice(voiceUrl);

  /// 音量を設定
  void setVolume(AudioChannel channel, double volume) {
    _manager.setChannelVolume(channel, volume);
  }

  /// マスター音量を設定
  void setMasterVolume(double volume) => _manager.setMasterVolume(volume);

  /// マネージャーを取得
  AudioManager get manager => _manager;
}
