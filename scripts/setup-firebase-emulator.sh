#!/bin/bash

# OpenDuelyst Firebase Emulator Setup Script
# This script sets up a local Firebase Realtime Database for development

set -e

echo "🔥 Setting up Firebase Emulator for OpenDuelyst development..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js v18 or later."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm."
    exit 1
fi

# Install Firebase CLI if not already installed
if ! command -v firebase &> /dev/null; then
    echo "📦 Installing Firebase CLI..."
    npm install -g firebase-tools
else
    echo "✅ Firebase CLI already installed"
fi

# Create firebase.json if it doesn't exist
if [ ! -f "firebase.json" ]; then
    echo "📝 Creating firebase.json configuration..."
    cat > firebase.json << EOF
{
  "database": {
    "rules": "firebaseRules.json"
  },
  "emulators": {
    "database": {
      "host": "localhost",
      "port": 9000
    },
    "ui": {
      "enabled": true,
      "host": "localhost",
      "port": 4000
    }
  }
}
EOF
else
    echo "✅ firebase.json already exists"
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "🔧 Creating .env file for local development..."
    cat > .env << EOF
FIREBASE_URL=http://localhost:9000/?ns=duelyst-local
FIREBASE_LEGACY_TOKEN=fake-token-for-local-development
EOF
    echo "✅ Created .env file with local Firebase configuration"
else
    echo "⚠️  .env file already exists. Please ensure it contains:"
    echo "   FIREBASE_URL=http://localhost:9000/?ns=duelyst-local"
    echo "   FIREBASE_LEGACY_TOKEN=fake-token-for-local-development"
fi

# Create a simple startup script
cat > start-emulator.sh << 'EOF'
#!/bin/bash
echo "🔥 Starting Firebase Emulator..."
echo "📊 Emulator UI will be available at: http://localhost:4000"
echo "🗄️  Database will be available at: http://localhost:9000"
echo ""
echo "Press Ctrl+C to stop the emulator"
echo ""

# Start the emulator with data persistence
if [ -d "./firebase-data" ]; then
    echo "📂 Loading existing emulator data..."
    firebase emulators:start --only database --import ./firebase-data
else
    echo "🆕 Starting fresh emulator (no existing data)"
    firebase emulators:start --only database
fi
EOF

chmod +x start-emulator.sh

echo ""
echo "🎉 Firebase Emulator setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Run './start-emulator.sh' to start the Firebase Emulator"
echo "2. In another terminal, build the game:"
echo "   yarn install --dev"
echo "   yarn tsc:chroma-js"
echo "   cross-env FIREBASE_URL=http://localhost:9000/?ns=duelyst-local yarn build"
echo "3. Initialize the database:"
echo "   docker compose up migrate"
echo "4. Start the game servers:"
echo "   docker compose up"
echo "5. Open http://localhost:3000 in your browser"
echo ""
echo "🔧 Emulator UI: http://localhost:4000"
echo "🗄️  Database: http://localhost:9000"
echo ""
echo "💾 To persist data between sessions:"
echo "   firebase emulators:export ./firebase-data"
echo "   (Data will be automatically loaded on next startup)"

