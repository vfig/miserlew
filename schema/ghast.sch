// Ghast

//AT STEADY STATE LEVELS
schema ghasta0
archetype AI_NONE
mono_loop 10 10
appa0__1 appa0__2 appa0__3 appa0__4 appa0__5 appa0__6
schema_voice vghast 1 atlevelzero
schema_voice vghast 1 atlevelone
schema_voice vghast 1 atleveltwo
schema_voice vghast 1 atlevelthree

//TO LEVEL 1 & 2, BACK
schema ghastto1
archetype AI_NONE
appa0__1 appa0__2 appa0__3 appa0__4 appa0__5 appa0__6
schema_voice vghast 1 tolevelone
schema_voice vghast 1 toleveltwo
schema_voice vghast 1 backtozero
schema_voice vghast 1 lostcontact


//TO LEVEL THREE
schema ghastto3
archetype AI_NONE
appa1__1
schema_voice vghast 1 spotplayer
schema_voice vghast 1 tolevelthree
schema_voice vghast 1 reactcharge

//TO LEVEL THREE
//schema ghastto3
//archetype AI_NONE
//appa3__1 appa3__2 appa3__3
//schema_voice vghast 1 spotplayer


//COMBAT HIT W/HIGH PTS
schema ghasthhi
archetype AI_NONE
apphhi_1 apphhi_2
schema_voice vghast 1 comhithigh
schema_voice vghast 1 comhitamb

//HIT W/LOW PTS
schema ghasthlo
archetype AI_NONE
apphlo_1 apphlo_2
schema_voice vghast 1 comhitlow

//DEATH
schema ghastdies
archetype AI_NONE
appdie
env_tag (Event Death) (CreatureType Apparition)
//schema_voice vghast 1 comdieloud
//schema_voice vghast 1 comdiesoft

// FEET
schema foot_ghast_a
archetype FOOT_AI
volume -1  //was -200
elemair1 elemair2 elemair3
env_tag (Event Footstep) (CreatureType Ghast) (Material Carpet Ceramic Chain Earth Flesh Glass Gravel Ice Liquid Ladder Metal Rope Stone Tile Vegetation Wood ZombiePart)

// GHAST SPELL SHOT
schema ghastshot
archetype WEAPONS
f_hm1
env_tag (Event Launch) (LaunchVel 1 1) (ArrowType GhastSpell)

// GHAST SPELL HIT
schema ghastshot_h
archetype HIT_PROJECTILE
hmagic1 hmagic2 hmagic3
env_tag (Event Death) (ArrowType GhastSpell)

// GHAST SPELL EXORCIZE
schema ghastshot_big
archetype HIT_PROJECTILE
egzap

