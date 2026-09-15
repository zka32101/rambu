# Phase 2: Bot Win Rate Balance Tuning (50±3%)

## Objective
Adjust AI evaluation parameters to achieve a first-player (sente) win rate of 50±3% in normal difficulty mode.

## Current Analysis

### Game Balance Mechanics
1. **First-move advantage**: Sente moves first
2. **Handicap system**: Gote receives one bonus move after sente's first turn
3. **Search depth**: Alpha-beta with depth=4
4. **Noise ranges by difficulty**:
   - Easy: ±5.0
   - Normal: ±1.0
   - Hard: ±0.3

### Evaluation Function Components (Normal Difficulty)

| Component | Weight | Value | Notes |
|-----------|--------|-------|-------|
| Piece Value | 50% (0.5) | Material count | Scales all pieces |
| HP Value | 50% (0.5) | Health state | Inverse weight to pieces |
| Position Bonus | Variable | Board position | Piece-type specific coefficients |
| Tempo Bonus | ±0.5 | Turn player | Current player gets +0.5 |
| Critical Adjacent | ±50.0 | King proximity | Very strong bonus |
| Critical Damage | ±30.0 | HP<=1 target | Strong offensive bonus |
| Enemy Major Piece | ±20.0 | Bishop/Rook attack | Strategic advantage |
| Full HP Bonus | ±5.0 | Piece durability | Minor defensive bonus |
| Enemy Low HP | ±15.0 | HP=1 opponent | Kill opportunity |
| Random Noise | ±1.0 | Randomization | Varied play |

## Tuning Strategy

### Phase 2a: Parameter Baseline Documentation
- Document current evaluation scoring
- Identify potential imbalance sources
- Quantify critical bonus impact

### Phase 2b: Systematic Adjustments
Likely adjustments needed (if testing shows imbalance):

1. **If Sente wins too much (>53%)**:
   - Reduce tempo bonus: 0.5 → 0.3
   - Reduce adjacent-to-king bonus: 50 → 40
   - Increase gote's critical evaluation bias
   - Reduce piece value weight slightly: 0.5 → 0.48

2. **If Gote wins too much (<47%)**:
   - Increase tempo bonus: 0.5 → 0.7
   - Increase sente's critical evaluation bias
   - Boost position value coefficient
   - Increase piece value weight: 0.5 → 0.52

3. **If variance is high (>3%)**:
   - Reduce normal noise range: 1.0 → 0.7
   - Stabilize critical bonus valuations
   - Reduce randomness in move selection

### Phase 2c: Testing Framework
- Run benchmark suite: 100 games for normal difficulty
- Target: 50% ±3% (47-53% acceptable range)
- Measure: Win rate, avg turns, game duration
- Track: Parameter combinations tested

## Implementation Approach

1. Create evaluation parameter class for centralized tuning
2. Add parameter adjustment documentation
3. Implement A/B testing utilities
4. Create benchmark reporting enhancements
5. Document all changes with rationale

## Success Criteria
- ✅ Sente win rate: 50% ±3% (47-53% range)
- ✅ Game duration: Reasonable (target: 30-60 turns average)
- ✅ No obvious strategy dominance
- ✅ Both players have viable winning paths

## Rollback Plan
If adjustments cause instability:
1. Revert to Phase 1 parameters
2. Make smaller incremental adjustments
3. Test after each parameter change
