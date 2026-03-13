# MG Common Game - API Documentation

## Overview

This document describes the API endpoints and services available in the MG Common Game framework.

## Table of Contents

1. [Authentication API](#authentication-api)
2. [User API](#user-api)
3. [Inventory API](#inventory-api)
4. [Shop API](#shop-api)
5. [Quest API](#quest-api)
6. [Achievement API](#achievement-api)
7. [Social API](#social-api)
8. [Chat API](#chat-api)
9. [Leaderboard API](#leaderboard-api)
10. [Guild API](#guild-api)
11. [Party API](#party-api)
12. [Season API](#season-api)

---

## Authentication API

### Login

**Endpoint:** `POST /auth/login`

**Request:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "string",
    "username": "string",
    "accessToken": "string",
    "refreshToken": "string",
    "tokenType": "Bearer",
    "expiresIn": 3600
  }
}
```

### Register

**Endpoint:** `POST /auth/register`

**Request:**
```json
{
  "username": "string",
  "email": "string",
  "password": "string"
}
```

**Response:** Same as login

### Refresh Token

**Endpoint:** `POST /auth/refresh`

**Request:**
```json
{
  "refreshToken": "string"
}
```

### Logout

**Endpoint:** `POST /auth/logout`

**Headers:** `Authorization: Bearer {token}`

---

## User API

### Get User Profile

**Endpoint:** `GET /users/{userId}`

**Response:**
```json
{
  "userId": "string",
  "username": "string",
  "email": "string",
  "level": 1,
  "xp": 0,
  "rank": "bronze",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

### Update User Profile

**Endpoint:** `PUT /users/{userId}`

**Request:**
```json
{
  "username": "string (optional)",
  "email": "string (optional)",
  "settings": {}
}
```

### Get User Progress

**Endpoint:** `GET /users/{userId}/progress`

**Response:**
```json
{
  "level": 5,
  "currentXP": 2500,
  "xpToNextLevel": 500,
  "rank": "silver",
  "stageId": "stage_2"
}
```

---

## Inventory API

### Get Inventory

**Endpoint:** `GET /inventory/{userId}`

**Response:**
```json
{
  "items": [
    {
      "itemId": "sword_1",
      "itemName": "Iron Sword",
      "quantity": 1,
      "itemType": "equipment",
      "durability": 100,
      "metadata": {}
    }
  ]
}
```

### Add Item

**Endpoint:** `POST /inventory/{userId}/items`

**Request:**
```json
{
  "itemId": "potion_1",
  "quantity": 5
}
```

### Remove Item

**Endpoint:** `DELETE /inventory/{userId}/items/{itemId}`

**Request:**
```json
{
  "quantity": 1
}
```

---

## Shop API

### Get Shop Items

**Endpoint:** `GET /shop/items`

**Query Parameters:**
- `category` (optional): Filter by category
- `currency` (optional): Filter by currency

**Response:**
```json
{
  "items": [
    {
      "itemId": "shop_item_1",
      "name": "Health Potion",
      "description": "Restores 100 HP",
      "basePrice": 50,
      "currencyId": "gold",
      "category": "consumable",
      "discount": 0.0
    }
  ]
}
```

### Purchase Item

**Endpoint:** `POST /shop/purchase`

**Request:**
```json
{
  "userId": "user_1",
  "itemId": "shop_item_1",
  "quantity": 1
}
```

---

## Quest API

### Get Quests

**Endpoint:** `GET /quests/{userId}`

**Response:**
```json
{
  "quests": [
    {
      "questId": "daily_1",
      "name": "Daily Quest",
      "description": "Complete 5 tasks",
      "questType": "daily",
      "status": "active",
      "progress": {
        "current": 3,
        "target": 5
      },
      "rewards": [
        {
          "type": "experience",
          "amount": 100
        }
      ]
    }
  ]
}
```

### Update Quest Progress

**Endpoint:** `POST /quests/{userId}/{questId}/progress`

**Request:**
```json
{
  "objectiveId": "obj_1",
  "progress": 1
}
```

### Claim Quest Rewards

**Endpoint:** `POST /quests/{userId}/{questId}/claim`

---

## Achievement API

### Get Achievements

**Endpoint:** `GET /achievements/{userId}`

**Query Parameters:**
- `category` (optional): Filter by category

**Response:**
```json
{
  "achievements": [
    {
      "achievementId": "first_win",
      "name": "First Victory",
      "description": "Win your first battle",
      "tier": "bronze",
      "category": "gameplay",
      "progress": 0.0,
      "isCompleted": true,
      "unlockedAt": "2024-01-01T00:00:00.000Z",
      "rewards": [
        {
          "type": "experience",
          "amount": 50
        }
      ]
    }
  ]
}
```

---

## Social API

### Get Friends List

**Endpoint:** `GET /social/{userId}/friends`

**Response:**
```json
{
  "friends": [
    {
      "userId": "friend_1",
      "username": "Friend One",
      "status": "online",
      "level": 10,
      "isOnline": true
    }
  ]
}
```

### Send Friend Request

**Endpoint:** `POST /social/{userId}/friends/requests`

**Request:**
```json
{
  "friendId": "user_2"
}
```

### Accept Friend Request

**Endpoint:** `POST /social/{userId}/friends/requests/{requestId}/accept`

---

## Chat API

### Get Messages

**Endpoint:** `GET /chat/channels/{channelId}/messages`

**Query Parameters:**
- `limit` (default: 50)
- `offset` (default: 0)

**Response:**
```json
{
  "messages": [
    {
      "messageId": "msg_1",
      "senderId": "user_1",
      "senderName": "User One",
      "content": "Hello!",
      "timestamp": "2024-01-01T00:00:00.000Z",
      "type": "text"
    }
  ]
}
```

### Send Message

**Endpoint:** `POST /chat/channels/{channelId}/messages`

**Request:**
```json
{
  "senderId": "user_1",
  "content": "Hello!"
}
```

---

## Leaderboard API

### Get Leaderboard

**Endpoint:** `GET /leaderboards/{leaderboardId}`

**Query Parameters:**
- `limit` (default: 100)
- `offset` (default: 0)

**Response:**
```json
{
  "entries": [
    {
      "rank": 1,
      "userId": "player_1",
      "username": "Player One",
      "score": 5000.0,
      "streak": 5
    }
  ]
}
```

### Submit Score

**Endpoint:** `POST /leaderboards/{leaderboardId}/scores`

**Request:**
```json
{
  "userId": "player_1",
  "score": 100.0
}
```

---

## Guild API

### Get Guild

**Endpoint:** `GET /guilds/{guildId}`

**Response:**
```json
{
  "guildId": "guild_1",
  "name": "Legendary Knights",
  "tag": "LEG",
  "description": "The best guild",
  "leaderId": "user_1",
  "level": 5,
  "members": [
    {
      "userId": "user_1",
      "username": "Leader",
      "role": "leader",
      "contribution": 1000
    }
  ],
  "maxMembers": 50
}
```

### Create Guild

**Endpoint:** `POST /guilds`

**Request:**
```json
{
  "name": "New Guild",
  "tag": "NEW",
  "description": "A new guild",
  "leaderId": "user_1"
}
```

---

## Party API

### Get Party

**Endpoint:** `GET /parties/{partyId}`

**Response:**
```json
{
  "partyId": "party_1",
  "name": "Dungeon Runners",
  "members": [
    {
      "userId": "user_1",
      "username": "Player One",
      "role": "leader",
      "level": 50,
      "isReady": true
    }
  ],
  "maxMembers": 4
}
```

### Create Party

**Endpoint:** `POST /parties`

**Request:**
```json
{
  "name": "My Party",
  "maxMembers": 4,
  "leaderId": "user_1"
}
```

---

## Season API

### Get Season

**Endpoint:** `GET /seasons/{seasonId}`

**Response:**
```json
{
  "seasonId": "season_1",
  "name": "Season 1: New Beginnings",
  "status": "active",
  "startTime": "2024-01-01T00:00:00.000Z",
  "endTime": "2024-03-31T00:00:00.000Z",
  "maxLevel": 100
}
```

### Get User Season Progress

**Endpoint:** `GET /seasons/{seasonId}/users/{userId}/progress`

**Response:**
```json
{
  "currentLevel": 25,
  "currentXP": 5000,
  "hasPremiumPass": true,
  "claimedFreeLevels": [1, 2, 3],
  "claimedPremiumLevels": [1, 2]
}
```

---

## Error Responses

All endpoints may return error responses in the following format:

```json
{
  "success": false,
  "error": "Error message",
  "statusCode": 400
}
```

### Common Error Codes

- `400`: Bad Request - Invalid parameters
- `401`: Unauthorized - Missing or invalid token
- `403`: Forbidden - Insufficient permissions
- `404`: Not Found - Resource not found
- `429`: Too Many Requests - Rate limit exceeded
- `500`: Internal Server Error - Server error

---

## Rate Limiting

API requests are rate-limited to prevent abuse:

- **Default Limit**: 100 requests per minute per user
- **Burst Limit**: 200 requests per minute per user

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1234567890
```

---

## Pagination

List endpoints support pagination via query parameters:

- `page`: Page number (default: 1)
- `pageSize`: Items per page (default: 20, max: 100)

Paginated responses include:

```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalPages": 5,
    "totalItems": 100
  }
}
```
