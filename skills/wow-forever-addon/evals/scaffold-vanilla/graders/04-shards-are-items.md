---
type: llm
focus: trace
weight: 1
---

Core.lua counts soul shards as bag items (C_Item.GetItemCount(6265) or a C_Container scan for item 6265), not via UnitPower or Enum.PowerType.SoulShards, which return 0 in Forever.
