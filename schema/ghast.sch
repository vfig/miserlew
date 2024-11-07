// GHAST DEATH
schema ghastdies
archetype AI_NONE
ghastdie
env_tag (Event Death) (CreatureType Ghast)

// FEET
schema foot_ghast_a
archetype FOOT_AI
volume -2500
ghast_ft1
env_tag (Event Footstep) (CreatureType Ghast)
env_tag (Event Footstep) (CreatureType Ghast) (Landing True)

// GHAST SPELL SHOT
schema ghastshot
archetype WEAPONS
f_hm1
env_tag (Event Launch) (LaunchVel 1 1) (ArrowType GhastSpell)

// GHAST SPELL LOOP
schema ghastshot_lp
archetype AMB
mono_loop 0 0
volume 0
eglaser

// GHAST SPELL HIT
schema ghastshot_h
archetype HIT_PROJECTILE
hmagic1 hmagic2 hmagic3
env_tag (Event Death) (ArrowType GhastSpell)

// GHAST SPELL EXORCIZE
schema ghastshot_big
archetype HIT_PROJECTILE
egzap

