<!-- Standing WoW Forever research questions. Append to questions.md, replacing <placeholders> with neutral
     nouns (an event, a data kind, an addon folder). Never state the goal; research must stay blind to task.md. -->

1. Which events fire when <trigger> happens, and what are their payloads? (See `references/events.md` and `references/forever-api-index.md#events`.)
2. Which Forever APIs expose <kind of data>, and what do they return? (See `references/forever-api-index.md`; signatures are in Gethe/wow-ui-source `forever`, `Blizzard_APIDocumentationGenerated/`.)
3. In <existing addon folder>, what happens on `ADDON_LOADED` and `PLAYER_LOGIN`, and in what order are its files loaded?
4. What SavedVariables shape does <existing addon folder> use (keys, nesting, version field, per-account vs per-character)?
5. Which frames, templates and slash commands does <existing addon folder> create, and where?
