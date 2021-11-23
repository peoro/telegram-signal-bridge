# telegram-signal-bridge
## Bridging telegram chats with signal ones

Telegram-signal-bridge is a tool to forward messages between a telegram chat and a signal one.

It uses a telegram bot on one side and relies on [signa-cli](https://github.com/AsamK/signal-cli)'s DBus interface on the other.

### Installation and step-by-step configuration

1. Clone this repo and enter the telegram-signal-bridge's directory.
1.1. Rename the configuration file: `cp config.example.js config.js`.
1.2. Install the dependencies: `npm install`.

2. Create a Telegram bot:
2.1. Register a new both with [@BotFather](https://t.me/BothFather).
2.2. Disable [privacy mode](https://core.telegram.org/bots#privacy-mode) for the bot.
2.3. Set the bot's token in `config.js`'s `telegram.token`.

3. Install and configure [signa-cli](https://github.com/AsamK/signal-cli):
3.1. Install it using whatever method you prefer (e.g. the ArchLinux AUR [signal-cli](https://aur.archlinux.org/packages/signal-cli/) package).
3.2. Connect it to the Signal network. Follow its documentation for more info.
3.3. Run it in in dbus/daemon mode: `signal-cli -u PHONE_NUMBER daemon`

4. Configure which groups to bridge:
4.1. Run telegram-signal-bridge: `npm run start`. It should print a line for every message it sees.
4.2. From its output, you should be able to spot the ID of the Telegram chat (numeric, often negative) and the Signal group (base64) you wish to bridge. Write them to `config.js`'s `telegram.group` and `signal.group`.
4.3. Restart telegram-signal-bridge. Everything should now work correctly.

### (Missing) Features

Currently telegram-signal-bridge is extremely minimal. It only forwards text messages between the two chats.

- It doesn't support chat events, stickers, images or other media.
- It crashes on error.
- It supports only one chat on the Telegram side (it can be a private chat, group or channel) and only one group on the Signal's side (it can't be a private chat).
- Expects `signal-cli` to run on the session DBus.

These and other shortcomings are quite simple to fix, if someone needs them.

### Community, support and development

Come join us on [@signal_bridge](https://t.me/signal_bridge) on telegram.
