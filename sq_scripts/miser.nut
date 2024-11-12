class FallLadder extends SqRootScript {
    function OnTurnOn() {
        local done = IsDataSet("Done");
        if (done)
            return;
        SetData("Done", 1);
        local rotvel = vector();
        rotvel.x = 1.0*Data.RandFltNeg1to1();
        rotvel.y = 1.0 + 2.0*Data.RandFlt0to1();
        rotvel.z = 2.0*Data.RandFltNeg1to1();
        if ("FallLadder_y" in userparams()) {
            local yFactor = userparams().FallLadder_y.tofloat();
            rotvel.y = rotvel.y*(yFactor);
        }
        SetProperty("PhysControl", "Controls Active", 0);
        Physics.Activate(self);
        SetProperty("PhysType", "Remove on Sleep", true);
        SetProperty("PhysState", "Rot Velocity", rotvel);
    }
}

class FlickerMomentary extends SqRootScript {
    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker
        && message().Op==eTweqOperation.kTweqOpFrameEvent) {
            SetProperty("RenderAlpha", 0.0);
            SetOneShotTimer("Unflicker", 0.2);
        }
    }

    function OnTimer() {
        if (message().name=="Unflicker") {
            SetProperty("RenderAlpha", 1.0);
        }
    }
}

class FrobLockSounds extends SqRootScript {
    function OnFrobWorldEnd() {
        Sound.PlayEnvSchema(self, "Event Reject, Operation OpenDoor",
            self, message().Frobber, eEnvSoundLoc.kEnvSoundAtObjLoc);
    }
}

class NotActuallyLoot extends SqRootScript {
    function OnBeginScript() {
        SwitchTextures("Stone");
    }

    function OnEndScript() {
        SwitchTextures("Gold");
        Object.RemoveMetaProperty(self, "M-NotActuallyLoot");
    }

    function OnContained() {
        local isPickup = (message().event==eContainsEvent.kContainAdd
            || message().event==eContainsEvent.kContainCombine);
        local isPlayer = Object.InheritsFrom(message().container, "Avatar");
        if (isPickup && isPlayer) {
            // Engine is hardcoded to change the name of an object with
            // "Loot" property to its loot stats when picked up. So we
            // change it back here, because it is junk right now!
            SetProperty("GameName", "");
        }
    }

    function SwitchTextures(keyPrefix) {
        local params = userparams();
        for (local i=0; i<4; i++) {
            local key = keyPrefix+i;
            local prop = "OTxtRepr"+i;
            if (key in params
            && HasProperty(prop)) {
                SetProperty(prop, params[key]);
            }
        }
    }
}

class TreasureSwitcher extends SqRootScript {
    // BUG: If you change from gold back to stone after the player picks some up
    //      (i.e. they have a loot stack in their inventory), then sometimes the
    //      junk will get combined into that loot pile. WONTFIX: For this mission,
    //      we ensure the player has no loot at all until after the stone->gold
    //      switch has happened; and we don't allow any gold->stone switch after
    //      the mission starts.

    function OnSim() {
        if (message().starting) {
            MakeLoot(false);
            OpenEyes(false);
        }
    }

    function OnTurnOn() {
        MakeLoot(true);
        OpenEyes(true);
    }

    function OnTurnOff() {
        // Disabled: we don't need it (and see bug note above).
        //MakeLoot(false);
        //OpenEyes(false);
    }

    function MakeLoot(becomeLoot) {
        if (becomeLoot) {
            Object.RemoveMetaPropertyFromMany("M-NotActuallyLoot", "@M-NotActuallyLoot");
        } else {
            Object.AddMetaPropertyToMany("M-NotActuallyLoot", "@SwitchTreasure,-@M-NotActuallyLoot");
        }
    }

    function OpenEyes(open) {
        if (open) {
            Object.RemoveMetaPropertyFromMany("M-EyesShut", "@M-HasEyes");
        } else {
            Object.AddMetaPropertyToMany("M-EyesShut", "@M-HasEyes,-@M-EyesShut");
        }
    }
}

class CloseYourEyes extends SqRootScript {
    function OnBeginScript() {
        SendMessage(self, "CloseYourEyes");
    }

    function OnEndScript() {
        SendMessage(self, "OpenYourEyes");
    }
}

class SwitchRepl extends SqRootScript {
    function OnCloseYourEyes() {
        SetReplTextures(false);
    }

    function OnOpenYourEyes() {
        SetReplTextures(true);
    }

    function SetReplTextures(on) {
        for (local i=0; i<4; ++i) {
            local key = (on? "On":"Off")+"R"+i;
            local prop = "OTxtRepr"+i;
            if (key in userparams()) {
                local tex = userparams()[key];
                SetProperty(prop, tex);
            }
        }
    }
}

/* ResLoot by FireMage, from The Black Parade. */
//Make Loot items get the ReplaceTextures properties for the newly stolen items
//so Loot using Replace Textures will keep their custom texture
//instead of displaying the ugly replace texture
class ResLoot extends SqRootScript
{
    function OnCombine()
    {
        //print("COMBINE : " +(message().combiner).tostring() + " " + self.tostring());
        local o = message().combiner;
        if(Property.Possessed(o,"OTxtRepr0"))
            SetProperty("OTxtRepr0",Property.Get(o,"OTxtRepr0"));
        if(Property.Possessed(o,"OTxtRepr1"))
            SetProperty("OTxtRepr1",Property.Get(o,"OTxtRepr1"));
        if(Property.Possessed(o,"OTxtRepr2"))
            SetProperty("OTxtRepr2",Property.Get(o,"OTxtRepr2"));
        if(Property.Possessed(o,"OTxtRepr3"))
            SetProperty("OTxtRepr3",Property.Get(o,"OTxtRepr3"));
    }
}

/* Sequence a pattern of TurnOn/TurnOff messages to a set of objects.
 *
 *    1. Add a ScriptParams link to each object to control, and set
 *       its data to a single letter A-Z.
 *
 *    2. Add a Design Note parameter, "Sequence", with the pattern
 *       made of comma-separated commands:
 *
 *           a      TurnOn object "a".
 *           !a     TurnOff object "a".
 *           123    pause for 123 milliseconds.
 *           stop   stop the sequence and turn off.
 *
 *    Turning the sequencer on will start the pattern from the beginning.
 *    Turning it off will stop the pattern, and turn off all the objects.
 */
enum SequenceAction {
    Stop,
    Wait,
    TurnOn,
    TurnOff,
}        
class Sequencer extends SqRootScript {
    parsed_sequence = [];

    function OnBeginScript() {
        EnableMe(false);
    }

    function OnTurnOn() {
        EnableMe(true);
    }

    function OnTurnOff() {
        EnableMe(false);
    }

    function OnTimer() {
        if (message().name=="SequencerWait") {
            DoNextStep();
        }
    }

    function EnableMe(enable) {
        if (enable) {
            local wasEnabled = (GetData("Enable")==1);
            if (! wasEnabled) {
                SetData("Enable", 1);
                SetData("Step", -1);
                SetData("Timer", 0);
                DoNextStep();
            }
        } else {
            local timer = GetData("Timer");
            if (timer!=null && timer!=0) {
                KillTimer(timer);
            }
            Link.BroadcastOnAllLinks(self, "TurnOff", "ScriptParams");
            SetData("Enable", 0);
            SetData("Step", -1);
            SetData("Timer", 0);
        }
    }

    function GetNextAction() {
        local seq = ParseSequence();
        if (seq.len()==0)
            return SequenceAction.Stop;
        local step = GetData("Step").tointeger()+1;
        if (step>=seq.len())
            step = 0;
        SetData("Step", step);
        return seq[step];
    }

    function DoNextStep() {
        while (true) {
            local action = GetNextAction();
            switch(action) {
            // Actions that are one-shot:
            case SequenceAction.Stop:
                EnableMe(false);
                return;
            case SequenceAction.Wait:
                local param = GetNextAction().tointeger();
                local s = param/1000.0;
                local t = SetOneShotTimer("SequencerWait", s);
                SetData("Timer", t);
                return;
            // Actions that keep looping:
            case SequenceAction.TurnOn:
                local who = GetNextAction().tostring();
                Link.BroadcastOnAllLinksData(self, "TurnOn", "ScriptParams", who);
                break;
            case SequenceAction.TurnOff:
                local who = GetNextAction().tostring();
                Link.BroadcastOnAllLinksData(self, "TurnOff", "ScriptParams", who);
                break;
            }
        }
    }

    function ParseSequence() {
        if (parsed_sequence.len()>0)
            return parsed_sequence;
        if (! ("Sequence" in userparams())) {
            parsed_sequence = [SequenceAction.Stop];
            return parsed_sequence;
        }
        local names = {};
        local links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local data = LinkTools.LinkGetData(link, "");
            names[data] <- true;
        }
        local pattern = userparams().Sequence;
        pattern = pattern.tostring()+",";
        local seq = [];
        local start = 0;
        while(start<pattern.len()) {
            local end = pattern.find(",", start);
            if (end==null)
                end = pattern.len();
            local bit = pattern.slice(start, end);
            start = end+1;
            local delay;
            try {
                delay = bit.tointeger();
            } catch(e) {
                delay = 0;
            }
            if (delay>0) {
                seq.push(SequenceAction.Wait);
                seq.push(delay);
            } else if (bit=="stop") {
                seq.push(SequenceAction.Stop);
                break;
            } else {
                local off = (bit.slice(0,1)=="!");
                if (off)
                    bit = bit.slice(1);
                if (! (bit in names)) {
                    print("WARNING: Sequencer "+self+" has no ScriptParams link matching '"+bit+"'");
                }
                seq.push(off? SequenceAction.TurnOff:SequenceAction.TurnOn);
                seq.push(bit);
            }
        }
        if (seq.len()>0) {
            parsed_sequence = seq;
        } else {
            parsed_sequence = [SequenceAction.Stop];
        }
        return parsed_sequence;
    }
}

class ForceField extends SqRootScript {
    function OnTurnOn() {
        Activate(true);
    }

    function OnTurnOff() {
        Activate(false);
    }

    function Activate(enable) {
        SetProperty("CollisionType", (enable? 1:0));    // Bounce / None
        SetProperty("RenderType", (enable? 0:1));       // Normal / Not Rendered
    }
}

/* LUGGED
   For any especially heavy-seeming object (e.g. corpses, boulders).
   When the player picks such a thing up, there's a sound effect and
   he is slowed.
   (copied from T2)
   */
class Lugged extends SqRootScript {
    function OnContained() {
        if (Object.InheritsFrom(message().container, "Avatar")) {
            if (message().event==eContainsEvent.kContainAdd) {
                Sound.PlaySchemaAmbient(self, "garlift");
                DrkInv.AddSpeedControl("LuggedHeavy", 0.6, 0.9);
            } else if (message().event==eContainsEvent.kContainRemove) {
                Sound.PlaySchemaAmbient(self, "gardrop");
                DrkInv.RemoveSpeedControl("LuggedHeavy");
            }
        }
    }
}

class StartsOff extends SqRootScript
{
    // Put this on a n object to send it TurnOff when the mission starts.

    function OnSim()
    {
        if (message().starting) {
            SendMessage(self, "TurnOff");
        }
    }
}

class PedestalPuzzle extends SqRootScript {
    function OnTurnOn() {
        local sender = message().from;
        if (! Link.AnyExist("ScriptParams", self, sender)) {
            Link.Create("ScriptParams", self, sender);
        }
        Update();
    }

    function OnTurnOff() {
        local sender = message().from;
        local link = Link.GetOne("ScriptParams", self, sender);
        if (link!=0) {
            Link.Destroy(link);
        }
        Update();
    }

    function GetInputState() {
        local inputs = {};
        local links = Link.GetAll("~ControlDevice", self);
        foreach (link in links) {
            local name = Object.GetName(LinkDest(link));
            if (name!=null) {
                inputs[name] <- false;
            }
        }
        links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local o = LinkDest(link);
            local name = Object.GetName(o);
            if (name!=null
            && name in inputs) {
                inputs[name] = true;
            }
        }
        return inputs;
    }

    function ApplyResults(results) {
        local targets = {};
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local o = LinkDest(link);
            local name = Object.GetName(o);
            if (name!=null) {
                targets[name] <- o;
            }
        }
        foreach (name,isOn in results) {
            if (! (name in targets)) continue;
            local o = targets[name];
            local link = Link.GetOne("ScriptParams", self, o);
            local wasOn = (link!=0);
            if (isOn && !wasOn) {
                Link.Create("ScriptParams", self, o);
                SendMessage(o, "TurnOn");
            } else if (!isOn && wasOn) {
                Link.Destroy(link);
                SendMessage(o, "TurnOff");
            }
        }
    }

    function Update() {
        local inputs = GetInputState();
        local results = Calculate(inputs);
        ApplyResults(results);
    }

    function Calculate(input) {
        local A = input["PedestalA"];
        local B = input["PedestalB"];
        local C = input["PedestalC"];
        local D = input["PedestalD"];
        local field1_open = (A || B) && !(A && B) || (C && D);
        local field2_open = (C && D);
        return {
            "ForceField1": !field1_open,
            "ForceField2": !field2_open,
        };
    }
}

class FaceNorth extends SqRootScript {
    function OnBeginScript() {
        PostMessage(self, "RestoreFacing");
    }

    function OnContained() {
        if (message().event==eContainsEvent.kContainRemove) {
            // Need to wait a frame for the teleport to work.
            PostMessage(self, "RestoreFacing");
        }
    }

    function OnRestoreFacing() {
        local f = vector(0.0,0.0,270.0);
        Object.Teleport(self, Object.Position(self), f);
    }
}

class FaceOutward extends SqRootScript {
    function OnBeginScript() {
        PostMessage(self, "RestoreFacing");
    }

    function OnContained() {
        if (message().event==eContainsEvent.kContainRemove) {
            // Need to wait a frame for the teleport to work.
            PostMessage(self, "RestoreFacing");
        }
    }

    function OnRestoreFacing() {
        local mid = 0.5*(Object.Position("PedestalA").x+Object.Position("PedestalB").x);
        local northern = (Object.Position(self).x<mid);
        local facing = vector(0.0,0.0,northern?90.0:270.0);
        Object.Teleport(self, Object.Position(self), facing);
    }
}

class MultiKeyLock extends SqRootScript {
    function OnTakeKey() {
        local key = message().data;
        // Try to place the key.
        local missingKeyCount = 0;
        local placedLink = 0;
        local links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local data = LinkTools.LinkGetData(link, "");
            if (data.tostring().tolower()=="multikeypos") {
                // Place this key first, then count empty places.
                if (placedLink==0) {
                    PlaceKeyAt(key, LinkDest(link));
                    placedLink = link;
                } else {
                    missingKeyCount++;
                }
            }
        }
        // Now we have finished iterating, we can destroy the link.
        if (placedLink!=0)
            Link.Destroy(placedLink);
        // Return true when all places are filled (whether we took this
        // key or not).
        Reply(missingKeyCount==0);
    }

    function PlaceKeyAt(key, marker) {
        local stackCount = 1;
        if (Property.Possessed(key, "StackCount")) {
            stackCount = Property.Get(key, "StackCount");
        }
        if (stackCount<=1) {
            Container.Remove(key);
        } else {
            Property.SetSimple(key, "StackCount", stackCount-1);
            key = Object.Create(key);
        }
        Property.Set(key, "PhysType", "Type", 3); // None
        Property.Set(key, "FrobInfo", "World Action", 0);
        Object.Teleport(key, vector(), vector(), marker);
        Link.Create("DetailAttachement", key, marker);
    }
}

class MultiKey extends SqRootScript {
    function OnFrobToolEnd() {
        // We let StdKey do its thing only if the key could not be placed.
        local key = message().SrcObjId;
        local lock = message().DstObjId;
        local fits = Key.TryToUseKey(key, lock, eKeyUse.kKeyUseCheck);
        local isPlayer = (message().Frobber==object("Player"));
        if (fits) {
            local allKeysPlaced = SendMessage(lock, "TakeKey", key);
            if (! allKeysPlaced) {
                local tags = "Event StateChange, LockState Unlocked";
                if (isPlayer)
                    tags = tags + ", CreatureType Player";
                Sound.PlayEnvSchema(lock , tags, lock, 0, eEnvSoundLoc.kEnvSoundAtObjLoc);
                BlockMessage();
            }
        }
    }
}

class SadimCrystal extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            Quest.Set("DidAttackCrystal", 0);
        }
    }

    function OnFrobWorldEnd() {
        if (! Object.HasMetaProperty(self, "FrobHeatSource")) {
            Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
        }
    }

    function OnTurnOff() {
        Object.RemoveMetaProperty(self, "FrobHeatSource");
    }

    function OnSlashStimStimulus() {
        if (message().intensity>=1.0) {
            HandleDamage();
        }
    }

    function OnPokeStimStimulus() {
        if (message().intensity>=1.0) {
            HandleDamage();
        }
    }

    function HandleDamage() {
        if (Quest.Get("goal_state_1")==0) {
            Quest.Set("goal_state_1", 2); // Cancel "Smash it"
            if (Quest.Get("goal_visible_1")!=0) {
                Quest.Set("goal_visible_2", 1); // "Instead, take it"
                Object.RemoveMetaProperty("TheSadimCrystal", "FrobInert");
            }
        }
    }
}

class ShowCrystalGoal extends SqRootScript {
    function OnFrobWorldEnd() {
        if (! IsDataSet("DidFrob")) {
            SetData("DidFrob", 1);
            SetOneShotTimer("ShowGoal", 0.5);
        }
    }

    function OnTimer() {
        if (message().name=="ShowGoal") {
            if (Quest.Get("goal_state_1")==0) {
                Quest.Set("goal_visible_1", 1); // "Smash it"
            } else {
                Quest.Set("goal_visible_3", 1); // "Take it"
                Object.RemoveMetaProperty("TheSadimCrystal", "FrobInert");
            }
        }
    }
}

class DebugSoundGrenade extends SqRootScript {
    function OnContained() {
        if (message().event==eContainsEvent.kContainRemove) {
            Sound.PlaySchemaAtObject(self, "debug_waterlp", self);
        } else {
            Sound.HaltSchema(self);
        }
    }
}

/* Sends TurnOn when the player or at least one object with sufficient
 * mass enters the room. Sends TurnOff when all such objects have left.
*/
class TrigRoomPlayerEtc extends SqRootScript {
    function OnPlayerRoomEnter() {
        Remember(message().MoveObjId);
    }
    function OnPlayerRoomExit() {
        Forget(message().MoveObjId);
    }
    function OnCreatureRoomEnter() {
        Remember(message().MoveObjId);
    }
    function OnCreatureRoomExit() {
        Forget(message().MoveObjId);
    }
    function OnObjectRoomEnter() {
        Remember(message().MoveObjId);
    }
    function OnObjectRoomExit() {
        Forget(message().MoveObjId);
    }

    function IsTriggerObj(o) {
        const massThreshold = 10.0;
        local isMovable = false;
        local isHeavyEnough = false;
        if (Property.Possessed(o, "PhysType")) {
            local type = Property.Get(o, "PhysType", "Type");
            isMovable = (type==1 || type==2); // Sphere, Sphere Hat
        }
        if (Property.Possessed(o, "PhysAttr")) {
            local mass = Property.Get(o, "PhysAttr", "Mass");
            isHeavyEnough = (mass>=massThreshold);
        }
        return (isMovable && isHeavyEnough);
    }

    function Remember(o) {
        if (IsTriggerObj(o)) {
            if (! Link.AnyExist("Population", self, o)) {
                Link.Create("Population", self, o);
            }
        }
        DoTrigger();
    }

    function Forget(o) {
        Link.DestroyMany("Population", self, o);
        DoTrigger();
    }

    function DoTrigger() {
        local wasOn = IsDataSet("Populated");
        local isOn = Link.AnyExist("Population", self);
        if (!wasOn && isOn) {
            SetData("Populated", "1");
            Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
        } else if (wasOn && !isOn) {
            ClearData("Populated");
            Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
        }
    }
}

/* StdTrap base class, ported from T2.
   Traps in general derive from this script and in so doing get the following
   basic infrastructure:
   * Handling of "TurnOn" and "TurnOff" messages, dispatched to an activation method.
   * Interpretation of locked or unlocked traps.
   * Interpretation of trap flags, such as Invert (reverse sense of on and off)
     NoOn and NoOff (intercept the handling of certain messages) and Once (destroy
     object after completion, or just lock it?)
*/
class SqStdTrap extends SqRootScript
{
// METHODS:
    function Activate(on, sender) {
        // overload me
    }

    function HandleMessage(on, sender) {
        const TRAPF_NONE   = 0x000;
        const TRAPF_ONCE   = 0x001;
        const TRAPF_INVERT = 0x002;
        const TRAPF_NOON   = 0x004;
        const TRAPF_NOOFF  = 0x008;
        local flags=0;
        local invert=false, activated=false;

        if(Property.Possessed(self,"TrapFlags"))
            flags=Property.Get(self,"TrapFlags");
        invert=flags&TRAPF_INVERT;
        if(!Locked.IsLocked(self) && sender!=self) {
            if(on && !(flags & TRAPF_NOON)) {
                Activate(!invert,sender);
                activated=true;
            } else if(!on && !(flags & TRAPF_NOOFF)) {
                Activate(invert,sender);
                activated=true;
            }
        }
        if(activated && (flags&TRAPF_ONCE))
            Property.Set(self,"Locked",true);
    }

// MESSAGES:

    function OnTurnOn() {
        HandleMessage(true,message().from);
    }

    function OnTurnOff() {
        HandleMessage(false,message().from);
    }

    function OnTimer() {
        if(message().name=="TurnOn")
            HandleMessage(true,message().from);
        else if(message().name=="TurnOff")
            HandleMessage(false,message().from);
    }
}

/* TrapTimedRelay, ported from T2, and slightly tweaked.
   Like a Relay Trap, but waits a certain amount of time before passing
   on the message.  If another message is received before the time passes,
   the previous message is never delivered. */
class SqTrapTimedRelay extends SqStdTrap
{
// METHODS:

    function GetTimeDelay(on) {
        if(Property.Possessed(self,"ScriptTiming"))
            return Property.Get(self,"ScriptTiming")/1000.0;
        return 1.0;
    }
 
    function Activate(on, sender) {
        local time_delay=GetTimeDelay(on);
        local msg=on?"TimedTurnOn":"TimedTurnOff";
        if (GetData("MessageTimer")!=0)
            KillTimer(GetData("MessageTimer"));
        local thandle = SetOneShotTimer(self,msg,time_delay);
        SetData("MessageTimer",thandle);
    }

// MESSAGES:
  
    function OnBeginScript() {
        if (!IsDataSet("MessageTimer"))
            SetData("MessageTimer",0);
    }

    function OnTimer() {
        if (message().name == "TimedTurnOn")
            Link.BroadcastOnAllLinks(self,"TurnOn","ControlDevice");
        if (message().name == "TimedTurnOff")
            Link.BroadcastOnAllLinks(self,"TurnOff","ControlDevice");
    }
}

class SqTrapTimedOffRelay extends SqTrapTimedRelay
{
    /* Like TrapTimedRelay Trap, but only delays TurnOff messages. */
    function GetTimeDelay(on) {
        if (on)
            return 0.0;
        else
            return base.GetTimeDelay(on);
    }
}

/* Auto-create AIWatchObj links when reaching a patrol point that has
 * Watch Link Defaults, or auto-trigger conversations when reaching a
 * patrol point with a Conversation.
 */
class PatrolActor extends SqRootScript
{
    function OnPatrolPoint() {
        local trol = message().patrolObj;
        if (Property.Possessed(trol, "AI_WtchPnt")) {
            if (! Link.AnyExist("AIWatchObj", self, trol)) {
                Link.Create("AIWatchObj", self, trol);
            }
        } else if (Property.Possessed(trol, "AI_Converation")) {
            if (! Link.AnyExist("AIConversationActor", trol)) {
                local link = Link.Create("AIConversationActor", trol, self);
                LinkTools.LinkSetData(link, "Actor ID", 1);
            }
            AI.StartConversation(trol);
        }
    }
}

/* Sends TurnOn when any objects of a given archetype (linked with a
 * ScriptParams("TrackArch") enter the room. Sends TurnOff if all of them
 * have left the room.
*/
class TrigArchetypeRoom extends TrigRoomPlayerEtc {
    function GetTrackedArchetype() {
        foreach (link in Link.GetAll("ScriptParams", self))
            if (LinkTools.LinkGetData(link,"")=="TrackArch")
                return LinkDest(link);
        return 0;
    }

    function IsTriggerObj(o) {
        return Object.InheritsFrom(o, GetTrackedArchetype());
    }
}


/* Removes FrobInert from ControlDevice targets on TurnOn. */
class TrapFrobErt extends SqRootScript {
    function OnTurnOn() {
        local meta = Object.Named("FrobInert");
        foreach (link in Link.GetAll("ControlDevice", self)) {
            Object.RemoveMetaProperty(LinkDest(link), meta);
        }
    }
}


class FlappyRat extends SqRootScript {
    // turn on joints for a bit, then turn it off and reset joint positions.
    // have a random time between turn ons.

    function OnBeginScript() {
        if (! IsDataSet("JointPos1")) {
            for (local i=1; i<=6; ++i) {
                SetData("JointPos"+i, GetProperty("JointPos", "Joint "+i));
            }
            SetOneShotTimer("FlapOn", 1.0);
        }
    }

    function OnTimer() {
        if (message().name=="FlapOn") {
            local animS = GetProperty("StTweqJoints", "AnimS");
            SetProperty("StTweqJoints", "AnimS", animS|1); // +On
            local delay = 0.5+1.0*Data.RandFlt0to1();
            SetOneShotTimer("FlapOff", delay);
        } else if (message().name=="FlapOff") {
            local animS = GetProperty("StTweqJoints", "AnimS");
            SetProperty("StTweqJoints", "AnimS", animS&~1); // -On
            local delay = 3.0+5.0*Data.RandFlt0to1();
            SetOneShotTimer("FlapOn", delay);
            for (local i=1; i<=6; ++i) {
                SetProperty("JointPos", "Joint "+i, GetData("JointPos"+i));
            }
        }
    }
}
