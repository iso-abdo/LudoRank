# LudoRank – Tournament & Match Management Business Rules

**Version:** 1.0

## 1. Objective
This document outlines the official business rules for managing tournaments within the LudoRank project. It defines system responsibilities, tournament/match management mechanisms, scoring criteria, and player ranking logic. This document serves as the primary reference for system development.

## 2. System Philosophy
LudoRank is a hybrid system that integrates:
* Ludo Game Engine execution.
* Tournament management.
* Automated scoring.
* Statistics tracking.
* Player ranking.

## 3. System Responsibilities
The system is responsible for:
* Creating and managing tournaments.
* Managing players.
* Managing matches.
* Executing the Ludo game.
* Determining player rankings upon match completion.
* Calculating scores.
* Updating the leaderboard.
* Generating statistics.

## 4. Non-System Responsibilities
The system is **not** responsible for the following, which remain under the control of the Tournament Manager:
* Selecting players for a specific match.
* Distributing players across matches.
* Determining the number of matches within a tournament.
* Enforcing a specific tournament structure.

## 5. Tournament Entity
Each tournament includes:
* **Name**, **Status**, **Configuration** (Number of players per match).
* **Constraints:** Unlimited number of players and matches.

### Tournament Statuses
| Status | Description |
| :--- | :--- |
| Draft | A new tournament |
| Running | Currently active tournament |
| Finished | Completed tournament |
| Cancelled | Terminated tournament |

## 6. Player Management
### Adding Players
Players can be added at any time (before, during, or after matches).
### Rules
* Any number of players may be added.
* **Constraint:** A player cannot be added more than once within the same tournament.

## 7. Match Management
Matches are created manually by the Tournament Manager.
### Validation Rules
Before saving a match, the system verifies:
* The correct number of players is selected.
* All players belong to the tournament.
* No duplicate players within the same match.

## 8. Scoring System
| Rank | 4-Player Match | 3-Player Match | 2-Player Match |
| :--- | :--- | :--- | :--- |
| 1st | 4 pts | 3 pts | 2 pts |
| 2nd | 3 pts | 2 pts | 1 pt |
| 3rd | 2 pts | 1 pt | - |
| 4th | 1 pt | - | - |

## 9. Leaderboard
* Players are ranked based on their **total points**.
* In the event of a tie in total points, players retain the same rank. No tie-breaking logic is currently enforced.

## 10. Statistics
The system maintains metrics for total matches, total points, count of placements (1st-4th), average points, and last match performance.

