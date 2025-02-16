# telegram-signal-bridge
## Bridging telegram chats with signal ones

Telegram-signal-bridge is a tool to forward messages between a Telegram chat and a Signal one.

It uses a Telegram bot on one side and relies on [signal-cli](https://github.com/AsamK/signal-cli)'s DBus interface on the other.

### Installation and step-by-step configuration

#### Option A: With Docker

1. Clone this repo and enter the telegram-signal-bridge's directory.
   * Rename the `.env` file: 
     ```shell
     cp .env.example .env
     ```
   * Specify the Signal account (phone number) you want to use by setting `SIGNAL_ACCOUNT`'s value in the `.env` file. It can be an existing account linked to your phone or a new dedicated account (landline numbers works!)
   * If you prefer to share your [signal-cli](https://github.com/AsamK/signal-cli)'s config with the host instead of using the default docker volume, set your host's config path in `.env` (E.g. `SIGNALCLI_CONFIG_VOL='~/.local/share/signal-cli'`)  

2. Create a Telegram bot:
    * Register a new bot with [@BotFather](https://t.me/BothFather).
    * Disable [privacy mode](https://core.telegram.org/bots#privacy-mode) for the bot.
    * Set the bot's token in `.env`'s `TELEGRAM_TOKEN`.

3. Configure [signal-cli](https://github.com/AsamK/signal-cli)
    * Run telegram-signal-bridge's Docker container in interactive mode: 
      ```shell
      docker compose run --rm -it --entrypoint /bin/ash telegram-signal-bridge
      ```
    * Register your account (or link signal-cli to an existing device) by following [signal-cli's documentation](https://github.com/AsamK/signal-cli/blob/master/README.md).
      * ℹ️ Tip: Landline numbers are supported by signal-cli, this way you could create a dedicated Signal bot account with it.
    * When you have finished (`signal-cli receive` works) you can exit the interactive container (`Ctrl+D`/`exit`)

4. Configure which groups to bridge:
   * Run the Docker Compose stack in foreground:
     ```shell
     docker compose up
     ```
   * Wait until you see `Telegram ready!` and `Signal ready!`
   * Send a message from the Telegram chat you want to bridge and a message from the Signal chat you want to bridge. It should print a line for every message it sees.
   * From its output, you should be able to spot the ID of the Telegram chat (numeric, often negative) and the Signal group (base64) you wish to bridge. Write them to `.env`'s `TELEGRAM_GROUP` and `SIGNAL_GROUP`.
   * Stop the stack (`Ctrl+C`). The bridge is ready, you can now run it in background if you want:
     ```shell
     docker compose up -d --force-recreate
     ```

_Note: if you get a "DBusError: The name org.asamk.Signal was not provided by any .service files" error, you need to increase the start delay, more info in `.env`_

#### Option B: Without Docker, locally

1. Clone this repo and enter the telegram-signal-bridge's directory.
   * Rename the env file: `cp .env.example .env`.
   * Install the dependencies: `npm install`.

2. Create a Telegram bot:
   * Register a new bot with [@BotFather](https://t.me/BothFather).
   * Disable [privacy mode](https://core.telegram.org/bots#privacy-mode) for the bot.
   * Set the bot's token in `.env`'s `TELEGRAM_TOKEN`.

3. Install and configure [signal-cli](https://github.com/AsamK/signal-cli):
   * Install it using whatever method you prefer (e.g. the ArchLinux AUR [signal-cli](https://aur.archlinux.org/packages/signal-cli/) package).
   * Register your account (or link signal-cli to an existing device) by following [signal-cli's documentation](https://github.com/AsamK/signal-cli/blob/master/README.md).
     * ℹ️ Tip: Landline numbers are supported by signal-cli, this way you could create a dedicated Signal bot account with it.
   * Run it in dbus/daemon mode in background (`SIGNAL_ACCOUNT` is your phone number with international prefix):
    ```shell
    signal-cli -a SIGNAL_ACCOUNT daemon --dbus&
    ```
4. Configure which groups to bridge:
   * Run telegram-signal-bridge: `npm run start`.
   * Wait until you see `Telegram ready!` and `Signal ready!`
   * Send a message from the Telegram chat you want to bridge and a message from the Signal chat you want to bridge. It should print a line for every message it sees.
   * From its output, you should be able to spot the ID of the Telegram chat (numeric, often negative) and the Signal group (base64) you wish to bridge. Write them to `.env`'s `TELEGRAM_GROUP` and `SIGNAL_GROUP`.
   * Restart telegram-signal-bridge. Everything should now work correctly.

### (Missing) Features

Currently, telegram-signal-bridge is extremely minimal. It only forwards text messages between the two chats.

- It doesn't support chat events, stickers, images or other media.
- It crashes on error.
- It supports only one chat on the Telegram side (it can be a private chat, group or channel) and only one group on the Signal's side (it can't be a private chat).
- Expects `signal-cli` to run on the session DBus.
- There's no guided interactive setup

These and other shortcomings are quite simple to fix, if someone needs them.

### Community, support and development

#### Docker
If you want to contribute to the project, there are docker-compose override files ready. By default, the dev overrides configs skip the code download part on image build, bind mount the current path to the container and decrease the start delay.  
```shell
docker compose -f docker-compose.yml -f docker-compose.override-dev.yml up
```

You can also build and test your prod image locally by specifying your fork repo url and branch/tag via the `GIT_REPO` and `GIT_TAG` build args  
```shell
docker compose -f docker-compose.yml build --build-arg GIT_REPO='https://github.com/<username>/telegram-signal-bridge' --build-arg GIT_TAG='<tag-or-branch>'
```

#### GitHub Action

Docker prod images are built and pushed automatically on ghcr.io for every semver git tags push and for every push on the main branch.  
You can add your fork branch [to the workflow](.github/workflows/docker-publish-test.yml) to let GitHub build and push images automatically on your fork's registry but **don't forget to revert** your changes before opening a PR 😉

#### Community
Come join us on Telegram: [@signal_bridge](https://t.me/signal_bridge)
