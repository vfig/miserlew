//GHAST 2 BROADCASTS -Geoff Stewart

/////////////
//AI SPEECH//
/////////////

//SLEEPING
schema gh2a0sn
archetype AI_NONE
volume -500
mono_loop 2000 3000
gh2a0sn1 gh2a0sn2 gh2a0sn3 gh2a0sn4
schema_voice vghast2 1 sleeping


//AT ALERT 0 - MUTTERING
// - ghasts are not happy and should mutter, not hum.
schema gh2a0
archetype AI_NONE
volume -500
mono_loop 7500 15000
gh2a0mu1 gh2a0mu2 gh2a0mu3 gh2a0cn1 gh2a0cn2 gh2a0cn3
schema_voice vghast2 1 atlevelzero
schema_voice vghast2 1 atlevelone 

//		- TALKING TO HIMSELF
schema gh2a0co
archetype AI_NONE
volume -500
mono_loop 7500 15000
gh2c1202 gh2c1204 gh2c1301 gh2c1303 gh2c1601 gh2c1603 gh2c1605
gh2c1702 gh2c1704 gh2c1802 gh2c1804
schema_voice vghast2 4 atlevelzero
schema_voice vghast2 4 atlevelone 


//TO ALERT 1
schema gh2a1
archetype AI_NONE
gh2a1__1 gh2a1__2 gh2a1__3 gh2a1__4 gh2a1__5 gh2a1__6  
schema_voice vghast2 1 tolevelone 

//		+sighted
schema gh2a1v
archetype AI_NONE
gh2a1v_1 gh2a1v_2
schema_voice vghast2 1 tolevelone (Sense Sight)

//		+heard
schema gh2a1h
archetype AI_NONE
gh2a1h_1 gh2a1h_2 gh2a1h_3
schema_voice vghast2 2 tolevelone (Sense Sound)

//		+w/co
schema gh2a1_w
archetype AI_MINOR
gh2a1_w1 gh2a1_w2
schema_voice vghast2 2 tolevelone (NearbyFriends 0 20)

//		+sighted +w/co
schema gh2a1vw
archetype AI_MINOR
gh2a1vw1 gh2a1vw2 gh2a1vw3 gh2a1vw4
schema_voice vghast2 5 tolevelone (Sense Sight) (NearbyFriends 0 20)

//		+heard +w/co
schema gh2a1hw
archetype AI_MINOR
gh2a1hw1 gh2a1hw2 gh2a1hw3 gh2a1hw4
schema_voice vghast2 5 tolevelone (Sense Sound) (NearbyFriends 0 20)


//AT ALERT 2 & 3
schema gh2at1
archetype AI_NONE
delay 5000
volume -500
mono_loop 5000 20000
gh2a0tc1 gh2a0tc2 gh2a0tc3
schema_voice vghast2 1 atleveltwo 
schema_voice vghast2 1 atlevelthree


//BACK TO ALERT 0
schema gh2bak
archetype AI_NONE
gh2bak_1 gh2bak_2 gh2bak_3 gh2bak_4 gh2bak_5 gh2bak_6 gh2bak_7 gh2bak_8 
schema_voice vghast2 1 backtozero 



//TO ALERT 2
schema gh2a2
archetype AI_MINOR
gh2a2__1 gh2a2__2 gh2a2__3 gh2a2__4 gh2a2__5
schema_voice vghast2 1 toleveltwo  

//		+sighted
schema gh2a2v
archetype AI_MINOR
gh2a2v_1 
schema_voice vghast2 1 toleveltwo (Sense Sight)  

//		+heard
schema gh2a2h
archetype AI_MINOR
gh2a2h_1 gh2a2h_2 gh2a2h_3
schema_voice vghast2 2 toleveltwo (Sense Sound)


//AT ALERT 2 +Investigating
schema gh2at2se
archetype AI_MINOR
delay 4500
mono_loop 10000 20000
no_repeat
gh2a2se1 gh2a2se2 gh2a2se3 gh2a2se4 gh2a3se2 gh2a3se3 gh2a3se4 
schema_voice vghast2 99 atleveltwo (Investigate True)


//TO ALERT 3
schema gh2a3
archetype AI_MAJOR
gh2a3s_2
schema_voice vghast2 1 tolevelthree

//SPOTTED THE PLAYER
schema gh2a3s
archetype AI_MORE_MAJOR
gh2a3s_1 gh2a3s_2 gh2a3s_3 gh2a3s_4
schema_voice vghast2 1 spotplayer

//(more s.p.)
schema gh2a3na
archetype AI_MORE_MAJOR
gh2a3na1 gh2a3na2 gh2a3na3 gh2a3na4 gh2a3na5 gh2a3na6 
schema_voice vghast2 1 spotplayer 

//		+carrying a body
schema gh2a3b
archetype AI_MORE_MAJOR
gh2a3b_1 
schema_voice vghast2 9 spotplayer (CarryBody True)

//		+w/co -All except THIEVE's
schema gh2telr
archetype AI_COMBAT
gh2telr1 gh2telr2 gh2telr3 gh2telr4 
schema_voice vghast2 3 spotplayer (NearbyFriends 0 20) (Mission 1 14)
schema_voice vghast2 3 spotplayer (NearbyFriends 0 20) (Mission 16 17)

//		+w/co -THIEVE's ONLY
schema gh2telr_m15
archetype AI_COMBAT
gh2telr1 gh2telr2 gh2telr4 
schema_voice vghast2 3 spotplayer (NearbyFriends 0 20) (Mission 15 15)


//LOST CONTACT W/PLAYER
schema gh2los
archetype AI_NONE
gh2los_1 gh2los_2 gh2los_3 gh2los_4
schema_voice vghast2 1 lostcontact  


//AT ALERT 3 +Investigating -All except THIEVES
schema gh2at3
delay 4500
mono_loop 10000 20000
no_repeat
archetype AI_MAJOR
gh2a2se1 gh2a2se2 gh2a2se3 gh2a2se4 gh2a3se1 gh2a3se2 gh2a3se3 gh2a3se4 
schema_voice vghast2 99 atlevelthree (Investigate True) (Mission 1 14)
schema_voice vghast2 99 atlevelthree (Investigate True) (Mission 16 17)

//		+Investigating -THIEVE's ONLY
schema gh2at3_m15
delay 4500
mono_loop 15000 25000
no_repeat
archetype AI_MAJOR
gh2a2se2 gh2a2se3 gh2a2se4 gh2a3se2 gh2a3se3 gh2a3se4 
schema_voice vghast2 99 atlevelthree (Investigate True) (Mission 15 15)


//RE-SPOTTED THE PLAYER +w/co -All except THIEVE's
schema gh2telc
archetype AI_COMBAT
gh2telc1 gh2telc2 gh2telc3 gh2telc4 gh2telc5 gh2telc6
schema_voice vghast2 5 spotplayer (NearbyFriends 0 20) (Reacquire True) (Mission 1 14)
schema_voice vghast2 5 spotplayer (NearbyFriends 0 20) (Reacquire True) (Mission 16 17)

//		+w/co -THIEVE's ONLY
schema gh2telc_m15
archetype AI_COMBAT
gh2telc1 gh2telc2 gh2telc3 gh2telc5
schema_voice vghast2 5 spotplayer (NearbyFriends 0 20) (Reacquire True) (Mission 15 15)


//REACT 1ST WARNING
schema gh2warn1
archetype AI_NONE
gh2wrn11
schema_voice vghast2 1 reactwarn

//REACT 2ND WARNING
schema gh2warn2
archetype AI_MINOR
gh2wrn21
schema_voice vghast2 1 reactwarn2

//REACT ATTACK AFTER FINAL WARNING
schema gh2warnf
archetype AI_MAJOR
gh2wrnf1
schema_voice vghast2 9 reactcharge (Reiterate 9 9)



//REACT CHARGE +alone
schema gh2chga
archetype AI_MORE_MAJOR
gh2chga1 gh2chga2 gh2chgw2
schema_voice vghast2 1 reactcharge

//		+w/co -All except THIEVE's
schema gh2chgw
archetype AI_COMBAT
gh2chgw1 gh2chgw2 gh2chgw3 gh2chgw4
schema_voice vghast2 2 reactcharge (NearbyFriends 0 20) (Mission 1 14)
schema_voice vghast2 2 reactcharge (NearbyFriends 0 20) (Mission 16 17)

//		+w/co -THIEVE's ONLY
schema gh2chgw_m15
archetype AI_COMBAT
gh2chgw2 gh2chgw3 gh2chgw4
schema_voice vghast2 2 reactcharge (NearbyFriends 0 20) (Mission 15 15)



//REACT GET READY TO FIRE YOUR BOW
schema gh2bow
archetype AI_MORE_MAJOR
no_repeat
gh2atb_1 gh2atb_2 gh2atb_3 gh2atn_1 gh2atw_2
schema_voice vghast2 1 reactshoot


//REACT RUN AWAY -All except THIEVE's
schema gh2runa
archetype AI_MAJOR
gh2runa1 gh2runa2 gh2runa3 gh2runa4
schema_voice vghast2 1 reactrun (Mission 1 14)
schema_voice vghast2 1 reactrun (Mission 16 17)

//		-THIEVE's ONLY
schema gh2runa_m15
archetype AI_MAJOR
gh2runa1 gh2runa2 gh2runa3
schema_voice vghast2 1 reactrun (Mission 15 15)


//REACT SOUND THE ALARMS
schema gh2alma
archetype AI_MORE_MAJOR
gh2alma1 gh2alma2 gh2alma3
schema_voice vghast2 1 reactalarm 

//		+w/co
schema gh2almw
archetype AI_COMBAT
gh2almw1 gh2almw2
schema_voice vghast2 3 reactalarm (NearbyFriends 0 20)



//FRUSTRATION
schema gh2frust
archetype AI_MAJOR
gh2bkd_1 gh2det_2 gh2runa3 gh2a3s_3 gh2a3se3
schema_voice vghast2 1 outofreach



//FOUND BODY
schema gh2bod
archetype AI_MORE_MAJOR
gh2bod_1 gh2bod_2 gh2bod_3
schema_voice vghast2 1 foundbody  



//FOUND SOMETHING MISSING -All except THIEVE's
schema gh2mis
archetype AI_MAJOR
gh2mis_1 gh2mis_3
schema_voice vghast2 2 foundmissing (Mission 1 14)
schema_voice vghast2 2 foundmissing (Mission 16 17)

//		-BAFFORD ONLY
schema gh2mis_miss2
archetype AI_MAJOR
gh2mis_2
schema_voice vghast2 1 foundmissing (Mission 2 2)

//		-SWORD ONLY
schema gh2mis_m06
archetype AI_MAJOR
gh2mis_4
schema_voice vghast2 1 foundmissing (Mission 6 6)

//		-THIEVE's ONLY
schema gh2mis_m15
archetype AI_MAJOR
gh2mis_3
schema_voice vghast2 1 foundmissing (Mission 15 15)



//NOTICED A TORCH BEING DOUSED
schema gh2torch
archetype AI_MINOR
delay 1000
gh2a1__4 gh2a1__5 gh2a1__6
schema_voice vghast2 1 noticetorch


//FOUND A SMALL ANOMALY
schema gh2sma
archetype AI_MINOR
gh2sma_1 gh2sma_2 gh2sma_3 gh2sma_4
schema_voice vghast2 1 foundsmall  

//FOUND A LARGE ANOMALY
schema gh2lar
archetype AI_MAJOR
gh2lar_1 gh2lar_2 gh2lar_3
schema_voice vghast2 1 foundlarge


//FOUND A SECURITY BREACH -All except THIEVE's
schema gh2sec
archetype AI_MORE_MAJOR
gh2sec_1 gh2sec_2 gh2sec_3 gh2sec_4
schema_voice vghast2 1 foundbreach (Mission 1 14)
schema_voice vghast2 1 foundbreach (Mission 16 17)

//		-THIEVE's ONLY
schema gh2sec_m15
archetype AI_MORE_MAJOR
gh2sec_1 gh2sec_2 gh2sec_3
schema_voice vghast2 1 foundbreach (Mission 15 15)


//RECENTLY SAW THE PLAYER +w/co -All except THIEVE's
schema gh2rint
archetype AI_INFORM
gh2rint1 gh2rint2 gh2rint3
schema_voice vghast2 1 recentintruder (Mission 1 14)
schema_voice vghast2 1 recentintruder (Mission 16 17)

//		-THIEVE's ONLY
schema gh2rint_m15
archetype AI_INFORM
gh2rint1 gh2rint2
schema_voice vghast2 1 recentintruder (Mission 15 15)


//RECENTLY FOUND BODY +w/co
schema gh2rbod
archetype AI_INFORM
gh2rbod1 gh2rbod2 gh2rbod3 
schema_voice vghast2 1 recentbody 



//RECENTLY FOUND SOMETHING MISSING +w/co -All except THIEVE's
schema gh2rmis
archetype AI_INFORM
gh2rmis1 gh2rmis2 gh2rmis4
schema_voice vghast2 1 recentmissing (mission 1 14)
schema_voice vghast2 1 recentmissing (mission 16 17)

//		+w/co -BAFF ONLY
schema gh2rmis_miss2
archetype AI_INFORM
gh2rmis3 
schema_voice vghast2 1 recentmissing (Mission 2 2)

//		+w/co -THIEVE's ONLY
schema gh2rmis_m15
archetype AI_INFORM
gh2rmis1
schema_voice vghast2 1 recentmissing (Mission 15 15)


//RECENTLY FOUND MISC ANAMOLY +w/co -All except THIEVE's
schema gh2roth
archetype AI_INFORM
gh2roth1 gh2roth2 gh2roth3 gh2roth4 gh2roth5
schema_voice vghast2 1 recentother (Mission 1 14)
schema_voice vghast2 1 recentother (Mission 16 17)

//		+w/co -THIEVE's ONLY
schema gh2roth_m15
archetype AI_INFORM
gh2roth1 gh2roth2 gh2roth3 gh2roth4
schema_voice vghast2 1 recentother (Mission 15 15)



//COMBAT

//ATTACKING +not losing
schema gh2atn
archetype AI_COMBAT
gh2atn_1 gh2atn_2 gh2atn_3 gh2atn_4 gh2atn_5 gh2atn_6 
schema_voice vghast2 1 comattack (ComBal Winning Even)

//		+winning
schema gh2atw
archetype AI_COMBAT
gh2atw_1 gh2atw_2
schema_voice vghast2 3 comattack (ComBal Winning)

//		+winning +w/co
schema gh2atww
archetype AI_COMBAT
gh2atww1 
schema_voice vghast2 3 comattack (ComBal Winning) (NearbyFriends 0 20)

//		+losing
schema gh2atl
archetype AI_COMBAT
gh2atl_1 gh2atl_2 gh2atl_3 
schema_voice vghast2 5 comattack (ComBal Losing)
schema_voice drunk1 1 comattack



//SUCCESSFULLY HIT THE PLAYER +not losing
schema gh2hit
archetype AI_COMBAT
gh2hit_1 gh2hit_2 gh2hit_3 gh2hit_4
schema_voice vghast2 1 comsucchit (ComBal Winning Even)

//		+not losing +w/co
schema gh2hitw
archetype AI_COMBAT
gh2hitw1 gh2hitw2
schema_voice vghast2 2 comsucchit (ComBal Winning Even) (NearbyFriends 0 20)



//SUCCESSFULLY BLOCKED THE PLAYER +not losing
schema gh2blk
archetype AI_COMBAT
gh2blk_1 gh2blk_2 gh2blk_3
schema_voice vghast2 1 comsuccblock (ComBal Winning Even)

//		+not losing +w/co
schema gh2blkw
archetype AI_COMBAT
gh2blkw1
schema_voice vghast2 2 comsuccblock (ComBal Winning Even) (NearbyFriends 0 20)


//HIT BY THE PLAYER W/HI HIT PTS 
schema gh2hhi
archetype AI_MAJOR
gh2hhi_1 gh2hhi_2 gh2hhi_3
schema_voice vghast2 1 comhithigh
schema_voice drunk1 1 comhithigh

//HIT BY THE PLAYER W/LO PTS 
schema gh2hlo
archetype AI_MORE_MAJOR
gh2hlo_1 gh2hlo_2 gh2hlo_3 gh2hlo_4
schema_voice vghast2 1 comhitlow
schema_voice drunk1 1 comhitlow

//		+w/co
schema gh2hlow
archetype AI_COMBAT
gh2hlow1
schema_voice vghast2 2 comhitlow (NearbyFriends 0 20)

//HIT BY THE PLAYER NO DAMAGE
schema gh2hnd
archetype AI_MAJOR
gh2hnd_1 gh2hnd_2 gh2hnd_3
schema_voice vghast2 1 comhitnodam


//BLOCKED BY THE PLAYER +not losing
schema gh2bkd 
archetype AI_COMBAT
gh2bkd_1 gh2bkd_2 gh2bkd_3
schema_voice vghast2 1 comblocked (ComBal Winning Even)

//		+not losing +w/co
schema gh2bkdw 
archetype AI_COMBAT
gh2bkdw1
schema_voice vghast2 5 comblocked (ComBal Winning Even) (NearbyFriends 0 20)


//DETECTED PLAYER TRYING TO BLOCK +not losing
schema gh2det 
archetype AI_COMBAT
gh2det_1 gh2det_2 gh2det_3
schema_voice vghast2 1 comdetblock (ComBal Winning Even)

//		+not losing +w/co
schema gh2detw 
archetype AI_COMBAT
gh2detw1
schema_voice vghast2 5 comdetblock (ComBal Winning Even) (NearbyFriends 0 20)



//AMBUSHED -HIT BY UNSEEN PLAYER
schema gh2amb 
archetype AI_MAJOR
gh2amb_1 gh2amb_2 gh2amb_3 gh2amb_4
schema_voice vghast2 1 comhitamb

//		+w/co
schema gh2ambw
archetype AI_COMBAT
gh2ambw1 gh2ambw2 gh2ambw3
schema_voice vghast2 5 comhitamb (NearbyFriends 0 20)


//DEATH BY COMBAT -LOUD
schema gh2diec
archetype AI_COMBAT
gh2diec1 gh2diec2 gh2diec3
schema_voice vghast2 1 comdieloud
schema_voice drunk1 1 comdieloud

//DEATH (or knocked out)BY AMBUSH -MORE MUFFLED
schema gh2diea
archetype AI_MINOR
volume -500
gh2diea1 gh2diea2 gh2diea3
schema_voice vghast2 1 comdiesoft
schema_voice drunk1 1 comdiesoft
