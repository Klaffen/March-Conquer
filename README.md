# March & Conquer

An auto-battle RTS built in Godot 4 where strategy wins — not reflexes.

## Gameplay

Recruit workers to automatically harvest Wood and Stone from the environment. Use resources to construct buildings that unlock troop types. Every troop you recruit increases your passive Gold income and automatically marches toward the enemy castle.

Your goal: destroy the enemy castle before they destroy yours.

## Core Loop

1. **Harvest** — Workers autonomously chop trees and mine rocks, clearing land in the process
2. **Build** — Spend Wood and Stone to construct buildings on cleared land
3. **Recruit** — Spend Gold on workers and troops
4. **March** — Troops automatically advance and fight without any direct control
5. **Conquer** — First side to reduce the enemy castle to 0 HP wins

## Resources

| Resource | Source | Used For |
|----------|--------|----------|
| Wood | Chopped trees | Buildings |
| Stone | Mined rocks | Buildings |
| Gold | Passive (scales with troops) | Workers, troops, upgrades |

## Built With

- [Godot 4](https://godotengine.org/)
