//GHAST 3 BROADSCASTS -Stephen Russell

/////////////
//AI SPEECH//
/////////////

//SLEEPING
schema gh3a0sn
archetype AI_NONE
volume -500
mono_loop 2000 3000
gh3a0sn1 gh3a0sn2 gh3a0sn3 
schema_voice vghast3 1 sleeping


//AT ALERT 0
// - ghasts are not happy and should mutter, not hum.
schema gh3a0
archetype AI_NONE
volume -500
mono_loop 7500 15000
gh3a0mu1 gh3a0mu2 gh3a0mu3 gh3a0tc1 gh3a0tc2 gh3a0tc3
schema_voice vghast3 1 atlevelzero
schema_voice vghast3 1 atlevelone

//      - TALKING TO HIMSELF
schema gh3a0ch
archetype AI_NONE
volume -500
delay 5000
gh3c2002 gh3c2004 gh3c2302 gh3c2401 gh3c2403 gh3c2502
gh3c3302 gh3c3402 gh3c3501 gh3c3601 gh3c3702 gh3c3801
mono_loop 7500 15000
schema_voice vghast3 4 atlevelzero
schema_voice vghast3 4 atlevelone

//		-SPARRING PARTNER ONLY
schema gh3a0wh
archetype AI_NONE
volume -500
mono_loop 1000 4000
gh3a0wh1 gh3a0wh2 gh3a0wh3
schema_voice vspar 1 atlevelzero


//TO ALERT 1, 2, 3, etc. -SPARRING PARTNER ONLY
schema gh3a0sp
archetype AI_NONE
volume -500
gh3a0wh3
schema_voice vspar 1 spotplayer
schema_voice vspar 1 tolevelone 
schema_voice vspar 1 toleveltwo 
schema_voice vspar 1 lostcontact  
schema_voice vspar 1 backtozero


//TO ALERT 1
schema gh3a1
archetype AI_NONE
gh3a1__1 gh3a1__2 gh3a1__3 gh3a1__4 gh3a1__4 gh3a1__5 
schema_voice vghast3 1 tolevelone  

//		+sighted
schema gh3a1v
archetype AI_NONE
gh3a1v_1
schema_voice vghast3 1 tolevelone (Sense Sight)

//		+heard
schema gh3a1h
archetype AI_NONE
gh3a1h_1 gh3a1h_2
schema_voice vghast3 2 tolevelone (Sense Sound)

//		+w/co
schema gh3a1_w
archetype AI_MINOR
gh3a1_w1 gh3a1_w2
schema_voice vghast3 3 tolevelone (NearbyFriends 0 20)

//		+sighted +w/co
schema gh3a1vw
archetype AI_MINOR
gh3a1vw1 gh3a1vw2 gh3a1vw3 gh3a1vw4
schema_voice vghast3 5 tolevelone (Sense Sight) (NearbyFriends 0 20)

//		+heard +w/co
schema gh3a1hw
archetype AI_MINOR
gh3a1hw1 gh3a1hw2 gh3a1hw3 gh3a1hw4
schema_voice vghast3 9 tolevelone (Sense Sound) (NearbyFriends 0 20)



//AT ALERT 2, 3
schema gh3at1
archetype AI_NONE
volume -500
delay 5000
mono_loop 7500 25000
gh3a0tc1 gh3a0tc2 gh3a0tc3
schema_voice vghast3 1 atleveltwo
schema_voice vghast3 1 atlevelthree
  

//BACK TO ALERT 0
schema gh3bak
archetype AI_NONE
gh3bak_1 gh3bak_2 gh3bak_3 gh3bak_4 gh3bak_5 gh3bak_6 gh3bak_7 
schema_voice vghast3 1 backtozero  


//TO ALERT 2
schema gh3a2
archetype AI_MINOR
gh3a2__1 gh3a2__2 gh3a2__3 gh3a2__4 gh3a2__5
schema_voice vghast3 1 toleveltwo  

//		+sighted
schema gh3a2v
archetype AI_MINOR
gh3a2v_1 
schema_voice vghast3 2 toleveltwo (Sense Sight)  

//		+heard
schema gh3a2h
archetype AI_MINOR
gh3a2h_1 gh3a2h_2 
schema_voice vghast3 5 toleveltwo (Sense Sound)



//AT ALERT 2 + Investigating, Also AT ALERT 3 THIEVE's ONLY
schema gh3at2
archetype AI_MINOR
delay 6000
mono_loop 10000 20000
no_repeat
gh3a2se1 gh3a2se2 gh3a2se3 gh3a2se4 gh3a3se1 gh3a3se2 gh3a3se4
schema_voice vghast3 99 atleveltwo (Investigate True)
schema_voice vghast3 99 atlevelthree (Investigate True) (Mission 15 15)



//TO ALERT 3
schema gh3a3
archetype AI_MAJOR
gh3a3s_1 gh3a3s_3
schema_voice vghast3 1 tolevelthree 



//SPOTTED THE PLAYER -All except THIEVE's
schema gh3a3s
archetype AI_MORE_MAJOR
gh3a3s_1 gh3a3s_2 gh3a3s_3 gh3a3s_4
schema_voice vghast3 1 spotplayer (Mission 1 14)
schema_voice vghast3 1 spotplayer (Mission 16 17)

//		-THIEVE's ONLY
schema gh3a3s_m15
archetype AI_MORE_MAJOR
gh3a3s_1 gh3a3s_2 gh3a3s_3 
schema_voice vghast3 1 spotplayer (mission 15 15)

//		-more spotted the player
schema gh3a3na
archetype AI_MORE_MAJOR
gh3a3na1 gh3a3na2 gh3a3na3 gh3a3na4 
schema_voice vghast3 1 spotplayer (Mission 1 14)
schema_voice vghast3 1 spotplayer (Mission 16 17)

//		-THIEVE's ONLY
schema gh3a3na_m15
archetype AI_MORE_MAJOR
gh3a3na1 gh3a3na2 gh3a3na4 
schema_voice vghast3 1 spotplayer (mission 15 15)

//		 +carrying a body
schema gh3a3b
archetype AI_MORE_MAJOR
gh3a3b_1 
schema_voice vghast3 9 spotplayer (CarryBody True)

//		+w/co -All except THIEVE's
schema gh3telr
archetype AI_COMBAT
gh3telr1 gh3telr2 gh3telr3 gh3telr4 
schema_voice vghast3 3 spotplayer (NearbyFriends 0 20) (Mission 1 14) 
schema_voice vghast3 3 spotplayer (NearbyFriends 0 20) (Mission 16 17) 

//		+w/co -THIEVE's ONLY
schema gh3telr_m15
archetype AI_COMBAT
gh3telr1 gh3telr2
schema_voice vghast3 3 spotplayer (NearbyFriends 0 20) (Mission 15)



//LOST CONTACT W/PLAYER -All except THIEVE's
schema gh3los
archetype AI_NONE
gh3los_1 gh3los_2 gh3los_3 gh3los_4
schema_voice vghast3 1 lostcontact (Mission 1 14) 
schema_voice vghast3 1 lostcontact (Mission 16 17) 

//		-THIEVE's ONLY
schema gh3los_m15
archetype AI_NONE
gh3los_1 gh3los_2 gh3los_3
schema_voice vghast3 1 lostcontact (mission 15 15) 



//AT ALERT 3 +Investigating
schema gh3at3
archetype AI_MAJOR
delay 6000
mono_loop 10000 20000
no_repeat
gh3a2se1 gh3a2se2 gh3a2se3 gh3a2se4 gh3a3se1 gh3a3se2 gh3a3se3 gh3a3se4
schema_voice vghast3 99 atlevelthree (Investigate True) (Mission 1 14)
schema_voice vghast3 99 atlevelthree (Investigate True) (Mission 16 17)


//RE-SPOTTED THE PLAYER AFTER A SEARCH
schema gh3telc
archetype AI_COMBAT
gh3telc1 gh3telc2 gh3telc3 gh3telc4 gh3telc5 
schema_voice vghast3 5 spotplayer (NearbyFriends 0 20) (Reacquire true)



//REACT 1ST WARNING
schema gh3warn1
archetype AI_NONE
gh3wrn11
schema_voice vghast3 1 reactwarn

//REACT 2ND WARNING
schema gh3warn2
archetype AI_MINOR
gh3wrn21
schema_voice vghast3 1 reactwarn2

//REACT ATTACK AFTER FINAL WARNING
schema gh3warnf
archetype AI_MORE_MAJOR
gh3wrnf1
schema_voice vghast3 9 reactcharge (Reiterate 9 9)


//REACT CHARGE +alone
schema gh3chga
archetype AI_MORE_MAJOR
gh3chga1 gh3chga2 
schema_voice vghast3 1 reactcharge

//REACT CHARGE +w/co
schema gh3chgw
archetype AI_MORE_MAJOR
gh3chgw1 gh3chgw2 gh3chgw3 
schema_voice vghast3 9 reactcharge (NearbyFriends 0 20)


//REACT TAUNT WHILE FIRING THE BOW
schema gh3bow
archetype AI_MORE_MAJOR
no_repeat
gh3atb_1 gh3atb_2 gh3atb_3 gh3atw_1 gh3atw_2 gh3chga1
schema_voice vghast3 1 reactshoot 


//REACT RUN AWAY
schema gh3runa
archetype AI_MAJOR
gh3runa1 gh3runa2 gh3runa3 gh3runa4
schema_voice vghast3 1 reactrun 


//REACT SOUND THE ALARMS
schema gh3alma
archetype AI_MORE_MAJOR
gh3alma1 gh3alma2 gh3alma3
schema_voice vghast3 1 reactalarm

//		+w/co
schema gh3almw
archetype AI_COMBAT
gh3almw1 gh3almw2
schema_voice vghast3 5 reactalarm (NearbyFriends 0 20)



//FRUSTRATION
schema gh3frust
archetype AI_MAJOR
gh3a3se4 gh3amb_2 gh3amb_3 gh3bkd_2 gh3det_2 gh3det_3
schema_voice vghast3 1 outofreach



//FOUND BODY -All except THIEVE's
schema gh3bod
archetype AI_MORE_MAJOR
gh3bod_1 gh3bod_2 
schema_voice vghast3 1 foundbody (Mission 1 14) 
schema_voice vghast3 1 foundbody (Mission 16 17) 

//		-THIEVE's ONLY
schema gh3bod_m15
archetype AI_MORE_MAJOR
gh3bod_1
schema_voice vghast3 1 foundbody (Mission 15 15)


//FOUND SOMETHING MISSING -All except THIEVE's
schema gh3mis
archetype AI_MAJOR
gh3mis_1 gh3mis_3
schema_voice vghast3 1 foundmissing (Mission 1 14)
schema_voice vghast3 1 foundmissing (Mission 16 17)

//		-BAFFORD ONLY
schema gh3mis_miss2
archetype AI_MAJOR
gh3mis_2
schema_voice vghast3 1 foundmissing (Mission 2 2)

//		-THIEVE's ONLY
schema gh3mis_m15
archetype AI_MAJOR
gh3mis_1
schema_voice vghast3 1 foundmissing (Mission 15 15)



//NOTICED A TORCH BEING DOUSED
schema gh3torch
archetype AI_MINOR
delay 1000
gh3sma_2 gh3a1__1 gh3a1__2 gh3a1__3 gh3a1__4 gh3a1__5 
schema_voice vghast3 1 noticetorch



//FOUND A SMALL ANOMALY
schema gh3sma
archetype AI_MINOR
gh3sma_1 gh3sma_2 
schema_voice vghast3 1 foundsmall  

//FOUND A LARGE ANOMALY
schema gh3lar
archetype AI_MAJOR
gh3lar_1 gh3lar_2 
schema_voice vghast3 1 foundlarge


//FOUND A SECURITY BREACH -All except THIEVE's
schema gh3sec
archetype AI_MORE_MAJOR
gh3sec_1 gh3sec_2 gh3sec_3 gh3sec_4
schema_voice vghast3 1 foundbreach (mission 1 14)
schema_voice vghast3 1 foundbreach (mission 16 17)

//		-THIEVE's ONLY
schema gh3sec_m15
archetype AI_MORE_MAJOR
gh3sec_1 gh3sec_3
schema_voice vghast3 1 foundbreach (mission 15 15)



//RECENTLY SAW THE PLAYER +w/co -All except THIEVE's
schema gh3rint
archetype AI_INFORM
gh3rint1 gh3rint2 gh3rint3
schema_voice vghast3 1 recentintruder (Mission 1 14)
schema_voice vghast3 1 recentintruder (Mission 16 17)

//		-THIEVE's ONLY
schema gh3rint_m15
archetype AI_INFORM
gh3rint1 gh3rint2
schema_voice vghast3 1 recentintruder (Mission 15 15)


//RECENTLY FOUND BODY +w/co -All except THIEVE's
schema gh3rbod
archetype AI_INFORM
gh3rbod1 gh3rbod2 gh3rbod3 
schema_voice vghast3 1 recentbody (mission 1 14)
schema_voice vghast3 1 recentbody (mission 16 17)

//		-THIEVE's ONLY
schema gh3rbod_m15
archetype AI_INFORM
gh3rbod1 gh3rbod2
schema_voice vghast3 1 recentbody 



//RECENTLY FOUND SOMETHING MISSING +w/co -All except THIEVE's
schema gh3rmis
archetype AI_INFORM
gh3rmis1 gh3rmis2 gh3rmis3 
schema_voice vghast3 1 recentmissing (mission 1 14)
schema_voice vghast3 1 recentmissing (mission 16 17)

//		-SWORD ONLY
schema gh3rmis_m06
archetype AI_INFORM
gh3rmis3 
schema_voice vghast3 1 recentmissing (mission 6 6)

//		-THIEVE's ONLY
schema gh3rmis_m15
archetype AI_INFORM
gh3rmis2
schema_voice vghast3 1 recentmissing (mission 15 15)



//RECENTLY FOUND MISC ANAMOLY +w/co -All except THIEVE's
schema gh3roth
archetype AI_INFORM
gh3roth1 gh3roth2 gh3roth3 gh3roth4 
schema_voice vghast3 1 recentother (mission 1 14)
schema_voice vghast3 1 recentother (mission 16 17)

//		-THIEVE's ONLY
schema gh3roth_m15
archetype AI_INFORM
gh3roth1 gh3roth2 gh3roth3
schema_voice vghast3 1 recentother (mission 15 15)



//COMBAT

//ATTACKING +not losing
schema gh3atn
archetype AI_COMBAT
gh3atn_1 freq 1
gh3atn_2 freq 1
gh3atn_3 freq 2
gh3atn_4 freq 2
gh3atn_5 freq 2
gh3atn_6 freq 2
schema_voice vghast3 1 comattack (ComBal Winning Even)
schema_voice vspar 1 comattack (ComBal Winning Even)

//		+winning
schema gh3atnw
archetype AI_COMBAT
gh3atw_1 gh3atw_2
schema_voice vghast3 3 comattack (ComBal Winning)
schema_voice vspar 3 comattack (ComBal Winning)

//		+winning +w/co
schema gh3atww
archetype AI_COMBAT
gh3atww1 
schema_voice vghast3 4 comattack (ComBal Winning) (NearbyFriends 0 20)

//		+losing
schema gh3atl
archetype AI_COMBAT
gh3atl_1 gh3atl_2 gh3atl_3 gh3atl_4
schema_voice vghast3 3 comattack (ComBal Losing)
schema_voice vspar 3 comattack (ComBal Losing)


//SUCCESSFULLY HIT THE PLAYER +not losing
schema gh3hit
archetype AI_COMBAT
gh3hit_1 gh3hit_2 gh3hit_3 gh3hit_4
schema_voice vghast3 1 comsucchit (ComBal Winning Even)
schema_voice vspar 1 comsucchit (ComBal Winning Even)

//		+not losing +w/co
schema gh3hitw
archetype AI_COMBAT
gh3hitw1 gh3hitw2
schema_voice vghast3 5 comsucchit (ComBal Winning Even) (NearbyFriends 0 20)



//SUCCESSFULLY BLOCKED THE PLAYER +not losing
schema gh3blk
archetype AI_COMBAT
gh3blk_1 gh3blk_2 gh3blk_3
schema_voice vghast3 1 comsuccblock (ComBal Winning Even)
schema_voice vspar 1 comsuccblock (ComBal Winning Even)

//		+not losing +w/co
schema gh3blkw
archetype AI_COMBAT
gh3blkw1
schema_voice vghast3 5 comsuccblock (ComBal Winning Even) (NearbyFriends 0 20)


//HIT BY THE PLAYER W/HI HIT PTS 
schema gh3hhi
archetype AI_MAJOR
gh3hhi_1 gh3hhi_2 gh3hhi_3
schema_voice vghast3 1 comhithigh
schema_voice vspar 1 comhithigh

//HIT BY THE PLAYER W/LO PTS 
schema gh3hlo
archetype AI_MORE_MAJOR
gh3hlo_1 gh3hlo_2 gh3hlo_3
schema_voice vghast3 1 comhitlow
schema_voice vspar 1 comhitlow

//		+w/co
schema gh3hlow
archetype AI_COMBAT
gh3hlow1 gh3ambw3 gh3hlo_2 gh3hlo_3
schema_voice vghast3 9 comhitlow (NearbyFriends 0 20)

//HIT BY THE PLAYER NO DAMAGE
schema gh3hnd
archetype AI_MAJOR
gh3hnd_1 gh3hnd_2 gh3hnd_3
schema_voice vghast3 1 comhitnodam
schema_voice vspar 1 comhitnodam


//BLOCKED BY THE PLAYER +not losing
schema gh3bkd 
archetype AI_COMBAT
gh3bkd_1 gh3bkd_2 gh3bkd_3
schema_voice vghast3 1 comblocked (ComBal Winning Even)
schema_voice vspar 1 comblocked (ComBal Winning Even)

//		+not losing +w/co
schema gh3bkdw 
archetype AI_COMBAT
gh3bkdw1
schema_voice vghast3 5 comblocked (ComBal Winning Even) (NearbyFriends 0 20)


//DETECTED PLAYER TRYING TO BLOCK +not losing
schema gh3det 
archetype AI_COMBAT
gh3det_1 gh3det_2 gh3det_3
schema_voice vghast3 1 comdetblock (ComBal Winning Even)
schema_voice vspar 1 comdetblock (ComBal Winning Even)

//		+not losing +w/co
schema gh3detw 
archetype AI_COMBAT
gh3detw1
schema_voice vghast3 5 comdetblock (ComBal Winning Even) (NearbyFriends 0 20)


//AMBUSHED -HIT BY UNSEEN PLAYER
schema gh3amb 
archetype AI_MAJOR
gh3amb_1 gh3amb_2 gh3amb_3 gh3amb_4
schema_voice vghast3 1 comhitamb

//		+w/co
schema gh3ambw
archetype AI_COMBAT
gh3ambw1 gh3ambw2 gh3ambw3
schema_voice vghast3 2 comhitamb (NearbyFriends 0 20)

//DEATH BY COMBAT -LOUD
schema gh3diec
archetype AI_COMBAT
gh3diec1 gh3diec2 gh3diec3
schema_voice vghast3 1 comdieloud

//DEATH (or knocked out)BY AMBUSH -MORE MUFFLED
schema gh3diea
archetype AI_MINOR
volume -1000
gh3diea1 gh3diea2 gh3diea3
schema_voice vghast3 1 comdiesoft








//MISSION 5

schema gh3m0203
archetype AI_NONE
gh3c3601 
schema_voice vghast3 1 SG_M0203

//SEEING GARRETT EXIT THE BLDG.
schema gh3m0501
archetype AI_COMBAT
gh3telc3 gh3runa3
schema_voice vghast3 1 sg_m0502



