# OpenDuelyst

![Duelyst Logo](app/resources/ui/brand_duelyst.png)

This is the source code for Duelyst, a digital collectible card game and
turn-based strategy hybrid developed by Counterplay Games and released in 2016.

## Production Deployment

Work is underway to deploy OpenDuelyst as "Duelyst Classic": a version of the
game exactly as it was in v1.96.17, before the servers were shut down. This is
being tracked in [issue #3](https://github.com/open-duelyst/duelyst/issues/3).

## Staging Deployment

The staging deployment is up and running at https://staging.duelyst.org. Both
single-player and multi-player games are available.

## Downloading the Desktop Clients

Desktop clients for Windows, Mac, and Linux can be downloaded on the
[Releases](https://github.com/open-duelyst/duelyst/releases) page.

Desktop clients currently use the staging environment. They'll use the
production environment once it's available.

## Playing on Android or iOS

We have basic support for playing on mobile web currently. From your phone's
browser, head to https://staging.duelyst.org to try it out.

To hide the status/navigation bar in Chrome or Safari, open the game and select
"Add to Home Screen". When you open the game from the home screen, the status
bar will be hidden.

## Contributing to OpenDuelyst

If you'd like to contribute to OpenDuelyst, check out our
[Documentation](docs/README.md), especially the [Roadmap](docs/ROADMAP.md) and
[Contributor Guide](docs/CONTRIBUTING.md).

You can also join the OpenDuelyst developer Discord server
[here](https://discord.gg/HhUWfZ9cxe). This Discord server is focused on the
development of OpenDuelyst, and has channels for frontend, backend, and
infrastructure discussions, but it is open for anyone to join.

## Filing Issues and Reporting Bugs

If you encounter a bug and would like to report it, first check the
[Open Issues](https://github.com/open-duelyst/duelyst/issues/) to see if the
bug has already been reported. If not, feel free to create a new issue with the
`bug` label.

If you would like to request a technical feature or enhancement to the code,
you can create a new issue with the `enhancement` label.

Since OpenDuelyst is currently focused on recreating the game as it last
existed in v1.96.17, please avoid creating feature requests related to balance
changes.

## Localization

The game currently includes English and German localization. If you'd like to
contribute translations for another language, take a look at the
`app/localization/locales` directory. You can copy the `en` folder and start
updating strings for the new language, then submit a Pull Request with your
contribution.

There are about 4,500 localized strings, so this can also be done a little bit
at a time. Once the translations are in, we can help get the language included
in the game.

## Local Development with Firebase Emulator

For developers who want to avoid setting up a Google Firebase account, you can use the Firebase Emulator Suite to run a local Firebase Realtime Database.

### Prerequisites

- Node.js v18 (recommended)
- Firebase CLI tools

### Setup Instructions

1. **Install Firebase CLI globally:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize Firebase in the project (if not already done):**
   ```bash
   firebase init database
   # Select "Use an existing project" and choose any project ID
   # Or select "Don't set up a default project" for local-only usage
   ```

3. **Start the Firebase Emulator:**
   ```bash
   firebase emulators:start --only database
   ```
   
   This will start a local Firebase Realtime Database on `http://localhost:9000`

4. **Configure your environment:**
   Create a `.env` file in the project root:
   ```bash
   FIREBASE_URL=http://localhost:9000/?ns=duelyst-local
   FIREBASE_LEGACY_TOKEN=fake-token-for-local-development
   ```

5. **Build and run the game:**
   ```bash
   # Install dependencies (if not already done)
   yarn install --dev
   yarn tsc:chroma-js
   
   # Build the game with local Firebase URL
   cross-env FIREBASE_URL=http://localhost:9000/?ns=duelyst-local yarn build
   
   # Initialize database
   docker compose up migrate
   
   # Start all services
   docker compose up
   ```

6. **Access the game:**
   Open http://localhost:3000 in your browser

### Firebase Emulator UI

The Firebase Emulator provides a web UI at http://localhost:4000 where you can:
- View and edit database contents
- Monitor real-time connections
- Debug Firebase security rules

### Notes

- The emulator data is ephemeral and will be lost when you stop the emulator
- For persistent local data, you can export/import emulator data:
  ```bash
  firebase emulators:export ./firebase-data
  firebase emulators:start --import ./firebase-data
  ```
- The fake legacy token works for local development but won't work with real Firebase

## License

OpenDuelyst is licensed under the Creative Commons Zero v1.0 Universal license.
You can see a copy of the license [here](LICENSE).
