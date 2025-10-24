# Supabase Migration Plan for OpenDuelyst

This document outlines a comprehensive plan to migrate OpenDuelyst from Firebase to Supabase, providing a self-hostable alternative that eliminates the need for external Google services.

## Overview

**Supabase** is an open-source Firebase alternative built on PostgreSQL with real-time capabilities. It provides:
- Real-time subscriptions (similar to Firebase Realtime Database)
- Authentication system
- PostgreSQL database (already used in Duelyst!)
- Self-hostable with Docker
- REST and GraphQL APIs
- Row Level Security (RLS) for data protection

## Migration Strategy: Phased Approach

### Phase 1: Infrastructure Setup & Static Data Migration (2-3 weeks)

#### 1.1 Supabase Local Setup
```bash
# Install Supabase CLI
npm install -g supabase

# Initialize Supabase in project
supabase init

# Start local Supabase stack
supabase start
```

#### 1.2 Database Schema Migration
- **Current**: Firebase JSON structure + PostgreSQL for some data
- **Target**: Unified PostgreSQL schema in Supabase

**Key Tables to Create:**
```sql
-- User management
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User inventory (replaces Firebase user-inventory tree)
CREATE TABLE user_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  item_type TEXT NOT NULL, -- 'card', 'spirit-orb', 'cosmetic', etc.
  item_id TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  metadata JSONB, -- For flexible item properties
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User stats (replaces Firebase user-stats tree)
CREATE TABLE user_stats (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  games_played INTEGER DEFAULT 0,
  games_won INTEGER DEFAULT 0,
  rank_current INTEGER,
  rank_top INTEGER,
  stats_data JSONB, -- For flexible stats storage
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievements (replaces Firebase user-achievements tree)
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  achievement_id TEXT NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE,
  progress JSONB,
  is_unread BOOLEAN DEFAULT true
);

-- User decks (replaces Firebase user-decks tree)
CREATE TABLE user_decks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  faction_id INTEGER,
  cards JSONB NOT NULL, -- Array of card IDs and counts
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 1.3 Data Migration Scripts
Create migration scripts to move data from Firebase to Supabase:

```javascript
// scripts/migrate-firebase-to-supabase.js
const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

class FirebaseToSupabaseMigrator {
  constructor() {
    this.supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
    this.firebase = admin.database();
  }

  async migrateUsers() {
    const usersSnapshot = await this.firebase.ref('users').once('value');
    const users = usersSnapshot.val();
    
    for (const [firebaseId, userData] of Object.entries(users)) {
      await this.supabase.from('users').insert({
        id: firebaseId, // Keep same ID for consistency
        username: userData.username,
        email: userData.email,
        created_at: new Date(userData.createdAt)
      });
    }
  }

  async migrateUserInventory() {
    const inventorySnapshot = await this.firebase.ref('user-inventory').once('value');
    const inventories = inventorySnapshot.val();
    
    for (const [userId, inventory] of Object.entries(inventories)) {
      // Migrate card collection
      if (inventory['card-collection']) {
        for (const [cardId, cardData] of Object.entries(inventory['card-collection'])) {
          await this.supabase.from('user_inventory').insert({
            user_id: userId,
            item_type: 'card',
            item_id: cardId,
            quantity: cardData.count || 1,
            metadata: cardData
          });
        }
      }
      
      // Migrate spirit orbs, cosmetics, etc.
      // ... similar pattern for other inventory types
    }
  }
}
```

### Phase 2: Authentication Migration (1-2 weeks)

#### 2.1 Replace Firebase Auth with Supabase Auth
- **Current**: Firebase legacy tokens + JWT validation
- **Target**: Supabase Auth with JWT

**Implementation:**
```javascript
// server/lib/supabase_auth.js
const { createClient } = require('@supabase/supabase-js');

class SupabaseAuthManager {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  async validateToken(token) {
    const { data: { user }, error } = await this.supabase.auth.getUser(token);
    if (error) throw error;
    return user;
  }

  async createUser(email, password, username) {
    const { data, error } = await this.supabase.auth.signUp({
      email,
      password,
      options: {
        data: { username }
      }
    });
    if (error) throw error;
    return data.user;
  }
}
```

#### 2.2 Update Client-Side Authentication
Replace Firebase auth calls with Supabase:

```javascript
// app/common/session2.coffee -> app/common/supabase_session.js
import { createClient } from '@supabase/supabase-js';

class SupabaseSession {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_ANON_KEY
    );
  }

  async signIn(email, password) {
    const { data, error } = await this.supabase.auth.signInWithPassword({
      email,
      password
    });
    if (error) throw error;
    return data.session;
  }

  async signOut() {
    const { error } = await this.supabase.auth.signOut();
    if (error) throw error;
  }

  onAuthStateChange(callback) {
    return this.supabase.auth.onAuthStateChange(callback);
  }
}
```

### Phase 3: Real-time Features Migration (3-4 weeks)

#### 3.1 Replace Firebase Realtime Database with Supabase Realtime

**Chat System Migration:**
```javascript
// app/ui/managers/chat_manager.js
class SupabaseChatManager {
  constructor() {
    this.supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
  }

  subscribeToConversation(conversationId, callback) {
    return this.supabase
      .channel(`conversation:${conversationId}`)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `conversation_id=eq.${conversationId}`
      }, callback)
      .subscribe();
  }

  async sendMessage(conversationId, message) {
    const { data, error } = await this.supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        body: message.body,
        from_id: message.fromId,
        to_id: message.toId
      });
    if (error) throw error;
    return data;
  }
}
```

**Game Session Real-time:**
```javascript
// Real-time game state synchronization
class SupabaseGameManager {
  subscribeToGameSession(gameId, callback) {
    return this.supabase
      .channel(`game:${gameId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'game_sessions',
        filter: `id=eq.${gameId}`
      }, callback)
      .subscribe();
  }

  async updateGameState(gameId, gameState) {
    const { data, error } = await this.supabase
      .from('game_sessions')
      .update({ state: gameState, updated_at: new Date() })
      .eq('id', gameId);
    if (error) throw error;
    return data;
  }
}
```

#### 3.2 Matchmaking System Migration
Replace Firebase queues with PostgreSQL + Supabase Realtime:

```sql
-- Matchmaking queue table
CREATE TABLE matchmaking_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  deck_id UUID REFERENCES user_decks(id),
  faction_id INTEGER,
  game_type TEXT DEFAULT 'ranked',
  ranking INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Game invites table
CREATE TABLE game_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID REFERENCES users(id),
  to_user_id UUID REFERENCES users(id),
  status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'declined'
  game_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);
```

### Phase 4: Advanced Features Migration (2-3 weeks)

#### 4.1 User Presence System
Replace Firebase presence with Supabase:

```sql
CREATE TABLE user_presence (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  status TEXT DEFAULT 'offline', -- 'online', 'offline', 'in_game'
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  game_id UUID, -- If currently in a game
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4.2 Daily Challenges & Quests
Migrate from Firebase to structured tables:

```sql
CREATE TABLE daily_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_date DATE UNIQUE NOT NULL,
  challenge_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE user_quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  quest_id TEXT NOT NULL,
  progress JSONB DEFAULT '{}',
  completed_at TIMESTAMP WITH TIME ZONE,
  is_daily BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Implementation Timeline

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Phase 1 | 2-3 weeks | Local Supabase setup, schema design, basic data migration |
| Phase 2 | 1-2 weeks | Authentication system replacement |
| Phase 3 | 3-4 weeks | Real-time features (chat, game sessions, matchmaking) |
| Phase 4 | 2-3 weeks | Advanced features (presence, challenges, notifications) |
| **Total** | **8-12 weeks** | Complete Firebase replacement |

## Configuration Changes

### Environment Variables
```bash
# Replace Firebase config with Supabase
SUPABASE_URL=http://localhost:54321  # Local development
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Remove Firebase variables
# FIREBASE_URL=...
# FIREBASE_LEGACY_TOKEN=...
```

### Docker Compose Updates
```yaml
# Add Supabase services to docker-compose.yaml
services:
  supabase-db:
    image: supabase/postgres:15.1.0.117
    environment:
      POSTGRES_PASSWORD: your-super-secret-and-long-postgres-password
    volumes:
      - ./supabase/volumes/db/data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  supabase-api:
    image: supabase/gotrue:v2.99.0
    depends_on:
      - supabase-db
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgresql://postgres:your-super-secret-and-long-postgres-password@supabase-db:5432/postgres
    ports:
      - "9999:9999"

  supabase-realtime:
    image: supabase/realtime:v2.25.35
    depends_on:
      - supabase-db
    environment:
      PORT: 4000
      DB_HOST: supabase-db
      DB_PORT: 5432
      DB_USER: postgres
      DB_PASSWORD: your-super-secret-and-long-postgres-password
      DB_NAME: postgres
    ports:
      - "4000:4000"
```

## Benefits of Migration

1. **Self-Hosted**: No dependency on Google Firebase
2. **Cost Control**: No Firebase pricing concerns
3. **Modern Stack**: PostgreSQL + modern real-time capabilities
4. **Better Performance**: Direct database queries vs Firebase limitations
5. **Unified Database**: Single PostgreSQL instance instead of Firebase + PostgreSQL
6. **Open Source**: Full control over the stack
7. **Better Development Experience**: Local development without external dependencies

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Real-time performance differences | High | Thorough testing, performance benchmarking |
| Data migration complexity | Medium | Incremental migration, rollback plans |
| Authentication edge cases | Medium | Comprehensive user testing, gradual rollout |
| Development timeline overrun | Low | Phased approach, MVP for each phase |

## Getting Started

1. **Set up local Supabase:**
   ```bash
   npm install -g supabase
   supabase init
   supabase start
   ```

2. **Create initial schema:**
   ```bash
   supabase migration new initial_schema
   # Edit the generated migration file with the schema above
   supabase db push
   ```

3. **Start with Phase 1** - migrate static user data first

4. **Test thoroughly** at each phase before proceeding

This migration plan provides a path to complete Firebase independence while maintaining all current functionality and improving the development experience.

