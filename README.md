# 🎯 HCYK Weapon License Test System

A comprehensive weapon license testing system for FiveM ESX servers. This resource provides an immersive and interactive UI for players to take weapon license tests, with customizable questions, admin controls, and detailed logging.

## ✨ Features

- **Interactive Test UI** - Beautiful and responsive user interface for the license exam
- **Customizable Questions** - Easily add, modify, or remove test questions
- **Admin Commands** - Grant or revoke licenses with convenient admin commands
- **Discord Webhooks** - Detailed logging of test results and admin actions
- **Multiple Notification Systems** - Integration with ESX, okok, and ox_lib notifications
- **Cooldown System** - Optional cooldown between test attempts
- **Database Storage** - Track test history and results

## 📋 Dependencies

- [ESX](https://github.com/esx-framework/esx-legacy)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)

## 💾 Installation

1. Download the resource
2. Place it in your server's resources folder
3. Add the following to your server.cfg:
```
ensure ox_lib
ensure ox_target
ensure hcyk_weapontests
```
4. Configure the `config.lua` file to your preferences
5. Set up your Discord webhook in the config if you want to use the logging features
6. Restart your server or start the resource

## ⚙️ Configuration

All configuration options are available in the `config.lua` file:

- Set the license fee
- Configure test parameters (passing score, question count, time limits)
- Customize NPC location and appearance
- Set up map blips
- Configure Discord webhook logging
- Set notification preferences
- Enable/disable cooldown periods

## 📝 Admin Commands

- `/grantlicense [playerId]` - Grant a weapon license to a player
- `/resetlicense [playerId]` - Revoke a weapon license from a player
- `/checklicense` - Check your own license status

Developer commands (debug mode only):
- `/weapontest` - Force open the test UI
- `/resetcooldown` - Reset the test cooldown timer

## 📊 Webhook Logging

The resource logs the following events to your Discord webhook:
- Test completions (passed/failed)
- License grants by admins
- License revocations by admins
- Including player identifiers, scores, and incorrect answers

## 🎨 UI Customization

The UI is built with React and can be easily customized by modifying the files in the `web/src` directory. After making changes, run:

```bash
cd web
npm install
npm run build
```

## 🤝 Support

For issues, feature requests, or support, please open an issue on the GitHub repository or contact the author on Discord.

## 📜 License

This resource is released under the MIT License. See the LICENSE file for details.

---

Created by Hatcyk | [GitHub](https://github.com/hatcyk)