# Phase 2: Bot Balance Tuning - Detailed Analysis

## Overview
Phase 2 focuses on adjusting AI evaluation parameters to achieve a target first-player (sente) win rate of 50±3% in normal difficulty mode.

## Game Mechanics Balance

### Current Balance Factors
1. **First-move advantage**: Sente moves first (typically 52-55% advantage in Shogi)
2. **Handicap system**: Gote receives one bonus move after Sente's first move
3. **Search depth**: Alpha-beta pruning with depth=4 (relatively shallow)
4. **Evaluation function**: Multi-factor scoring system

### Expected Impact Analysis

| Factor | Effect | Magnitude |
|--------|--------|-----------|
| First-move advantage | Sente +3% to +5% | Medium |
| Handicap (Gote bonus move) | Gote +2% to +3% | Medium |
| Balanced HP/Piece evaluation | Neutral | None |
| Shallow search depth | Possibly favors consistent evaluator | Low |

**Expected baseline**: With handicap, we should see close to 50% win rate, but:
- If first-move + tempo bonus > handicap benefit → Sente wins more
- If handicap benefit > first-move + tempo bonus → Gote wins more

## Evaluation Function Deep Dive

### Component Scoring

#### 1. Material Value (Piece Count)
```
Score = Σ(White pieces) - Σ(Black pieces)
Applied weight: 50% (normal difficulty)
Typical piece values:
  - Pawn: 1.0
  - Knight/Lance: 3.0
  - Silver/Gold: 5.5
  - Bishop/Rook: 9.0
  - King: 999.0
```

**Analysis**: Balanced component. Both players should have similar material initially.

#### 2. HP Value
```
Score = Σ(White piece HP ratio) - Σ(Black piece HP ratio)
Applied weight: 50% (normal difficulty)
```

**Analysis**: Players with higher HP advantage score higher. Incentivizes preservation.

#### 3. Position Bonus
```
Score = Σ(Piece position bonuses)
Multiplier by piece type (0.1-0.25)
Table: Bonuses for middle and enemy territory
```

**Analysis**: Encourages piece advancement. Coefficient small enough not to dominate.

#### 4. Tempo Bonus
```
Current player: +0.5
Other player: -0.5
```

**Analysis**: Small bonus for turn player. May be insufficient or excessive:
- If AI uses 4-level depth, turn player at level 4 is opponent
- This could create oscillating evaluation bias

#### 5. Critical Situation Bonuses
These are the largest components:

```
Adjacent to king:         ±50.0
Critical damage possible: ±30.0
Can attack major piece:   ±20.0
Full HP bonus:            ±5.0
Enemy low HP (=1):        ±15.0
```

**Analysis**: Extremely large relative to piece values. Could cause:
- Excessive king safety focus
- Premature attack commitments
- Overvaluation of late-game threats

## Theoretical Imbalance Sources

### Scenario 1: If Sente Wins >53%
Likely causes:
1. **Tempo bonus too high**: 0.5 might be excessive given shallow search
2. **Critical bonuses too generous**: Sente's aggressive strategy is overrewarded
3. **First-move advantage not offset**: Handicap benefit not fully exploited by evaluation
4. **Position bonus orientation**: Might implicitly favor Sente's forward direction

Mitigation strategies:
- Reduce tempo bonus: 0.5 → 0.3-0.4
- Scale down critical bonuses: multiply by 0.7-0.8
- Reduce piece value weight slightly: 0.5 → 0.48
- Increase HP weight importance

### Scenario 2: If Gote Wins >53% (Sente <47%)
Likely causes:
1. **Handicap too powerful**: Bonus move advantage is overvalued
2. **Tempo bonus too weak**: Doesn't reflect turn value
3. **Search depth bias**: Depth=4 might not explore consequence chains
4. **Critical bonuses under-weighted**: Defensive situations are undervalued

Mitigation strategies:
- Increase tempo bonus: 0.5 → 0.6-0.7
- Boost piece value weight: 0.5 → 0.52-0.55
- Increase critical bonuses by 10-20%
- Enhance king safety evaluation

## Parameter Tuning Strategy

### Phase 2a: Baseline Documentation (10 games)
Establish current win rate with Phase 1 parameters.

### Phase 2b: Tempo Variation Test (5+ tempos × 5 games)
Test tempo bonus values from 0.2 to 0.8 in 0.1 increments:
```
Rationale: Tempo bonus is smallest, easiest to adjust parameter
Expected outcome: Linear or near-linear relationship with win rate
Expected range: ~2-4% win rate delta per 0.1 tempo change
```

### Phase 2c: Parameter Set Comparison (5 sets × 10 games)
Test pre-defined parameter sets:
1. **Baseline**: Phase 1 parameters
2. **SenteReduced**: All bonuses -10-20%, tempo 0.3
3. **SenteStrengthened**: All bonuses +10%, tempo 0.7
4. **CriticalReduced**: Critical bonuses -30%, tempo 0.5
5. **Balanced**: Moderate reductions across board

### Phase 2d: Validation (40+ games)
Run best parameter set for minimum 40 games to confirm stability.

## Success Criteria

### Primary Metrics
- ✅ Sente win rate: 50% ±3% (47-53% range)
- ✅ Minimum games: 40 for significance (95% CI ≈ ±7%)
- ✅ No obvious dominant strategy for either player

### Secondary Metrics
- Game duration: 30-80 turns average
- Move variety: >5 different first moves in 10 games
- Evaluation stability: Parameter tweaks <0.5% per change

## Expected Outcomes by Parameter

### Tempo Bonus Sensitivity
```
Tempo 0.2: ~48% (slight Gote advantage)
Tempo 0.3: ~49%
Tempo 0.4: ~50% (ideal)
Tempo 0.5: ~51%
Tempo 0.6: ~52%
Tempo 0.7: ~53% (Sente advantage)
Tempo 0.8: ~54%
```

(These are estimates based on typical search patterns)

### Critical Bonus Sensitivity
Reducing critical bonuses by ~30%:
- Pros: Smoother game progression, reduces sudden collapses
- Cons: Late-game tactical play less valued
- Expected win rate impact: +1-2% for Gote

### Piece Value Weight Sensitivity
Increasing piece value weight (vs HP weight):
- Pros: More consistent piece counting
- Cons: Less incentive for HP preservation
- Expected win rate impact: +1-2% for Sente (material advantage matters more)

## Implementation Notes

### Code Structure
- `EvaluationParams`: Encapsulates all tunable parameters
- `BenchmarkUtils`: Systematic testing framework
- `AIEngine`: Accepts optional params override
- `test/phase2_parameter_test.dart`: Automated test suite

### Parameter Adjustment Process
1. Create new `EvaluationParams` constant in `evaluation_params.dart`
2. Test with `BenchmarkUtils.runBenchmark(..., params: newParams)`
3. Analyze results with `BenchmarkUtils.printComparisonReport(...)`
4. Once validated, update default in `AIEngine._getDefaultParams()`

### Rollback Plan
If adjustments destabilize game:
1. Revert to Phase 1 parameters
2. Make smaller incremental changes (0.1 steps instead of 0.2)
3. Test after each change with 20 games minimum
4. Consider reverting to mixed parameter strategy if needed

## Next Steps (Phase 3)

Once Phase 2 parameters are finalized:
1. Update `EvaluationConstants` with confirmed values
2. Remove parameter override capability (or keep for testing)
3. Proceed to Phase 3: Highlight video generation
4. Benchmark confirmed parameters in full 100-game suite

## References
- `lib/services/ai_engine.dart`: Current evaluation implementation
- `lib/services/evaluation_params.dart`: Parameter definitions
- `lib/services/benchmark_utils.dart`: Testing utilities
- `lib/utils/constants.dart`: Original constants
- `CLAUDE.md`: Full project specification
