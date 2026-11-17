-- Lint fixture: must FAIL scripts/lint.sh with NEVER-EMIT, W113, W143 and W111.
local _, ns = ...

ns.name = GetContainerItemInfo(0, 1)    -- never-emit (Classic Era global)
ns.fake = C_Fake.Foo()                  -- W113: invented namespace
ns.nope = C_Container.NotARealFunction(0) -- W143: invented field on a real namespace
leaked = 1                              -- W111: global leak
