# Business Rules
## LudoRank
Version: 1.0
Status: Draft

---

# 1. Introduction

This document defines the official Business Rules of the LudoRank platform.

These rules are the single source of truth for the application.

Any implementation in the database, domain layer, UI, or game engine must follow these rules.

---

# 2. Project Scope

LudoRank consists of two connected systems.

1. Tournament Management System
2. Interactive Ludo Game Engine

The Tournament System is responsible for managing tournaments.

The Game Engine is responsible for playing the actual Ludo match.

After each match finishes, the Game Engine automatically sends the final result to the Tournament Engine.

---

# 3. General Principles

The application is:

- Offline First
- Local Database
- No Internet Required
- Fast
- Simple
- Fair
- Automatic Score Calculation

---

# 4. Player Rules

A player can:

- Be created.
- Be edited.
- Be archived.
- Participate in multiple tournaments.
- Participate in multiple matches.

A player cannot:

- Participate twice in the same match.
- Participate twice in the same tournament.

Each player has a permanent unique identifier.

---

# 5. Tournament Rules

Each tournament has:

- Unique ID
- Name
- Creation Date
- Status
- Rules
- Players
- Matches

Tournament Status:

- Draft
- Ready
- Running
- Finished
- Archived

Only Draft tournaments can be edited freely.

Running tournaments cannot change player lists.

Finished tournaments become read-only.

---

# 6. Tournament Player Rules

A player joins a tournament only once.

Each tournament stores its own player statistics.

Player statistics inside Tournament are independent from global statistics.

---

# 7. Match Rules

A match belongs to exactly one tournament.

A match has:

- ID
- Tournament
- Round
- Players
- Status
- Winner
- Start Time
- Finish Time

Match Status:

- Waiting
- Ready
- Running
- Finished
- Cancelled

---

# 8. Match Player Rules

Each MatchPlayer belongs to:

- One Match
- One Player

Each MatchPlayer stores:

- Final Position
- Points Earned
- Score
- Is Winner
- Is Withdrawn

---

# 9. Supported Match Types

The application supports:

- 2 Players
- 3 Players
- 4 Players

The number of players is fixed before the tournament starts.

---

# 10. Point System

## Two Players

1st Place = 2 Points

2nd Place = 1 Point

---

## Three Players

1st Place = 3 Points

2nd Place = 2 Points

3rd Place = 1 Point

---

## Four Players

1st Place = 4 Points

2nd Place = 3 Points

3rd Place = 2 Points

4th Place = 1 Point

Points are calculated automatically after each match.

---

# 11. Winner Rules

Each match has exactly one winner.

The winner is determined by the Game Engine.

Manual winner selection is not allowed.

---

# 12. Ranking Rules

Tournament ranking is based on Total Points.

The player with the highest total points ranks first.

Ranking updates automatically after every finished match.

---

# 13. Tie Rules

If two or more players have the same number of points:

Tie-breaking rules will be applied.

(Currently Pending Final Decision)

Suggested priority:

1. Total Wins
2. Head-to-Head Result
3. Total Kills
4. Least Last Places
5. Shared Position

---

# 14. Withdrawal Rules

A player may withdraw before or during a tournament.

If a player withdraws during a match:

- The player receives the last available position.
- The player receives the points of the last position.
- The player is marked as Withdrawn.

Previous finished matches remain unchanged.

Future matches will follow the tournament withdrawal policy.

---

# 15. Match Cancellation Rules

Cancelled matches:

- Give no points.
- Do not affect rankings.
- Remain stored in history.

---

# 16. Automatic Calculations

After every finished match the system automatically updates:

- Match Result
- Player Points
- Tournament Ranking
- Statistics
- Wins
- Losses

No manual calculations are allowed.

---

# 17. Statistics

The system calculates:

- Matches Played
- Wins
- Losses
- Total Points
- Average Points
- Win Rate
- First Places
- Last Places
- Longest Win Streak
- Total Withdrawals

Statistics are updated automatically.

---

# 18. Game Engine Responsibility

The Game Engine is responsible for:

- Dice
- Turn Order
- Piece Movement
- Kill Rules
- Safe Zones
- Home Rules
- Winning Detection

The Tournament Engine must never calculate gameplay.

---

# 19. Tournament Engine Responsibility

The Tournament Engine is responsible for:

- Tournament Creation
- Player Assignment
- Match Generation
- Ranking
- Statistics
- Leaderboard

It does not control gameplay.

---

# 20. Manual Editing Rules

Administrators (or tournament owner) may edit:

- Tournament Name
- Notes

Administrators cannot manually edit:

- Winner
- Points
- Rankings

unless using future Admin Override functionality.

---

# 21. Data Integrity Rules

Every entity has a unique ID.

Deleting a tournament does not delete players.

Deleting a player is not allowed if historical matches exist.

Historical data must never be lost.

---

# 22. Future Features

Reserved for:

- Online Sync
- Cloud Backup
- Multiplayer
- Friends
- Achievements
- Seasons
- ELO Ranking
- AI Match Analysis

---

End of Document