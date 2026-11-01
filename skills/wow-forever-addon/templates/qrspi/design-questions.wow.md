<!-- WoW Forever design questions to ask in the Design phase, alongside the command's own.
     Each points at the skill reference that frames the trade-off. -->

1. **Ace3 or vanilla?** Options panel, profiles, modules or cross-addon messaging favour Ace3. Otherwise go vanilla. (See `references/ace3-vs-vanilla.md`.)
2. **Event-driven or `OnUpdate`?** Is there an event for the change, or does it need polling? If it polls, at what throttle interval? (See `references/performance.md`.)
3. **SavedVariables scope:** per account, per character, or both? What is the schema and version field, and is a migration needed? (See `references/saved-variables.md`.)
4. **Secure-frame exposure:** does the addon touch protected functions, action buttons, unit frames or anything that must work in combat? How is combat lockdown handled? (See `references/taint-and-secure.md`.)
5. **UI framework:** plain frames with templates, or AceGUI / AceConfigDialog? Where is it anchored, and is it movable or saved? (See `references/widgets.md`.)
