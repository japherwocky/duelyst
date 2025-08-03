#!/bin/bash

# OpenDuelyst Docker Development Setup Script
# This script sets up the complete development environment using Docker

set -e

echo "🐳 Setting up OpenDuelyst development environment with Docker..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Check if yarn is installed
if ! command -v yarn &> /dev/null; then
    echo "❌ Yarn is not installed. Please install Yarn first."
    echo "   Visit: https://yarnpkg.com/getting-started/install"
    exit 1
fi

echo "✅ Docker and Yarn are available"

# Install dependencies
echo "📦 Installing dependencies..."
yarn install --dev

# Compile TypeScript for chroma-js
echo "🔧 Compiling TypeScript dependencies..."
yarn tsc:chroma-js

# Build the game
echo "🏗️  Building the game..."
yarn build

echo ""
echo "🎉 Setup complete! Starting the development environment..."
echo ""
echo "📋 Services that will be started:"
echo "   🔥 Firebase Emulator (Database: :9000, UI: :4001)"
echo "   🗄️  PostgreSQL Database (:5432)"
echo "   📡 Redis (:6379)"
echo "   🎮 Game API (:3000)"
echo "   ⚔️  Game Server (:8001)"
echo "   🤖 SP Server (:8000)"
echo "   👷 Worker Process"
echo ""
echo "🚀 Starting all services..."

# Start all services
docker compose up --build

echo ""
echo "🎮 Game should be available at: http://localhost:3000"
echo "🔥 Firebase Emulator UI: http://localhost:4001"
echo ""
echo "Press Ctrl+C to stop all services"

