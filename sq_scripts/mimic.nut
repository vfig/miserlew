/* TODO
    also want to have eye effects ParticleAttached/DetailAttached
    to archetypes.
*/

/* Objects involved in possession:

     - Target: The object to be possessed, in the player's understanding. The
       target must have M-Possessable or M-PossessableMovable, and a
       ~DetailAttachement link from the Pointer (these may be configured on
       the target's archetype or on the target concrete itself).
       A target should also have a ~DetailAttachement or ~ParticleAttachement
       link from the Eyes.

     - Pointer: An instance of PossessPoint that marks where the camera should
       go.

     - Eyes: When turned off, a visual indication of where the possess spell
       should be cast to, and when turned on visual feedback of a possession
       about to happen.
*/

const USE_VIEWMODEL = true;
const USE_PLAYERLIMBS_API = true;
const PREVENT_DESELECT = true;

const POSSESS_POINT_RADIUS = 1.0;

// NOTE: The player arm joint 1 position and orientation differs when using
//       PlayerLimbs vs Weapon (presumably due to the motions used). If we used
//       a custom mesh and custom motions, we could presumably nullify that;
//       but we have the stock meshes and motions, so we need to account for it.
//       These globals allow the viewmodel placement to be tweaked by hand in
//       the test mission.
// TODO: maybe try just using a transparent bjachand limb model instead, with
//       the same creature tags as the blackjack, so we get the same motion
//       set?
local g_ViewmodelPos, g_ViewmodelFac;
if (USE_PLAYERLIMBS_API) {
    g_ViewmodelPos = vector(-0.0246241,-0.428078,-0.527131);
    g_ViewmodelFac = vector(0,1.3,145.5);
} else {
    g_ViewmodelPos = vector(0.2,0.2,2.0);
    g_ViewmodelFac = vector(0.0,0.0,0.0);
}

const g_minCastTime = 0.75;

/* Converts TurnOn/TurnOff into possession/dispossession of the CD-linked
 * object, or self if there is no outgoing CD link. */
class TrapPossess extends SqRootScript {
    function OnTurnOn() {
        local player = Object.Named("Player");
        local link = Link.GetOne("ControlDevice", self);
        local target = (link!=0)? LinkDest(link) : self;
        SendMessage(player, "Possess", target);
    }

    function OnTurnOff() {
        local player = Object.Named("Player");
        local link = Link.GetOne("ControlDevice", self);
        local target = (link!=0)? LinkDest(link) : self;
        SendMessage(player, "Dispossess", target);
    }
}

class Possessor extends SqRootScript {
    // Possess: sent from anything, asks to begin possessing the 'data' object.
    function OnPossess() {
        local target = message().data.tointeger();
        DoPossess(target);
    }

    // Dispossess: sent from anything, asks to stop possessing the 'data' object.
    // Has no effect if the player is not already doing so.
    function OnDispossess() {
        local target = message().data.tointeger();
        DoDispossess(target);
    }

    function OnBeginScript() {
        // Create the objects we need; we will just keep them around forever.
        local anchor = Object.BeginCreate("fnord");
        Property.SetSimple(anchor, "ModelName", "unitsfer");
        Property.Set(anchor, "PhysType", "Type", 0); // OBB
        Property.Set(anchor, "PhysType", "# Submodels", 1);
        Property.Set(anchor, "PhysDims", "Size", vector());
        Property.Set(anchor, "PhysControl", "Controls Active", 8|16); // Location|Rotation
        Property.SetSimple(anchor, "CollisionType", 0); // No collision
        Property.SetSimple(anchor, "PhysCanMant", false);
        Property.SetSimple(anchor, "PhysAIColl", false);
        Object.EndCreate(anchor);

        local terrpt1 = Object.BeginCreate("fnord");
        Property.SetSimple(terrpt1, "ModelName", "unitsfer");
        Object.EndCreate(terrpt1);

        local terrpt2 = Object.BeginCreate("fnord");
        Property.SetSimple(terrpt2, "ModelName", "unitsfer");
        Object.EndCreate(terrpt2);

        local link = Link.Create("ScriptParams", self, anchor);
        LinkTools.LinkSetData(link, "", "PossessAnchor");

        Link.Create("TPathInit", anchor, terrpt1);
        Link.Create("TPathNext", anchor, terrpt2);

        link = Link.Create("TPath", terrpt1, terrpt2);
        LinkTools.LinkSetData(link, "Speed", 0.0);
        LinkTools.LinkSetData(link, "Pause (ms)", 0);
        LinkTools.LinkSetData(link, "Path Limit?", true);
        link = Link.Create("TPath", terrpt2, terrpt1);
        LinkTools.LinkSetData(link, "Speed", 0.0);
        LinkTools.LinkSetData(link, "Pause (ms)", 0);
        LinkTools.LinkSetData(link, "Path Limit?", true);

        Property.Set(anchor, "MovingTerrain", "Active", false);
    }

    function OnPossessUpdate() {
        if (IsDataSet("IsPossessing")) {
            UpdateAttachPosition();
            PostMessage(self, "PossessUpdate");
        }
    }

    function GetPossessAnchor() {
        foreach (link in Link.GetAll("ScriptParams", self))
            if (LinkTools.LinkGetData(link, "")=="PossessAnchor")
                return LinkDest(link);
        return 0;
    }

    function GetTerrPt1(anchor) {
        local link = Link.GetOne("TPathInit", anchor);
        if (link==0)
            return 0;
        return LinkDest(link);
    }

    function GetTerrPt2(terrpt1) {
        local link = Link.GetOne("TPath", terrpt1);
        if (link==0)
            return 0;
        return LinkDest(link);
    }

    function FindPossessPoint(target) {
        return SendMessage(target, "GetPossessPoint");
    }

    function AttachOffset(target) {
        // Get the player's head and body position relative to their origin.
        // Headbob and lean will affect this a little, but we are ignoring that.
        // The main thing is to properly handle standing vs crouched difference.
        // NOTE: CalcRelTransform() returns the position of the child object
        //       relative to the given submodel of the parent object; but we
        //       want the submodel position relative to the parent origin,
        //       which is the inverse; hence the negations.
        local submodelOffset = vector();
        local ignoreFacing = vector();
        Object.CalcRelTransform(self, self, submodelOffset, ignoreFacing, 4, 0); // 4=RelSubPhysModel, 0=PLAYER_HEAD
        local isCrouched = (-submodelOffset.z<=0);

        // TODO: use Camera.GetPosition(), Camera.GetFacing() ??

        // We don't want the actual head position though, as if that is off the
        // default when we measure (due to headbob/lean) then the camera will
        // drift off our ideal attach point as the spring relaxes. So here we
        // hardcode the head offsets (from PHYSAPI.H, PHMODATA.C):
        local playerHeadZ = 1.8
        if (isCrouched) playerHeadZ += -2.02;

        // When carrying a body the submodel positions are adjusted. We use
        // the PlayerLimbs service for the viewmodel, which sadly hardcodes
        // the carry-body mode. Not really an issue for this mission, but we
        // need to account for the change in camera pos (from PHMODATA.C).
        if (USE_VIEWMODEL && USE_PLAYERLIMBS_API) playerHeadZ += -0.8;

        // The camera position is not at the center of the player's head
        // submodel, but a little bit higher ("eyeloc" in PHMOAPI.CPP).
        local eyeloc = 0.8;
        if (DarkGame.ConfigIsDefined("eyeloc")) {
            local f = float_ref();
            DarkGame.ConfigGetFloat("eyeloc", f);
            eyeloc = f.tofloat();
        }
        local eyeZ = playerHeadZ+eyeloc;

        local pointer = FindPossessPoint(target);
        return CalcAttachOffset(target, pointer, eyeZ)
    }

    function CalcAttachOffset(target, pointer, eyeZ) {
        // PhysAttach offset is always relative to the attached object but in
        // global orientation.
        local eyeOffset = vector(0,0,-eyeZ);
        // BUG: When there is no pointer, the calculation below ends up wrong,
        //      and the attach position ends up not moving with the target.
        //      Won't fix for now: just make sure we always have pointers.
        local relTo = (pointer!=0)? pointer : target;
        return Object.Position(relTo)+eyeOffset-Object.Position(target);
    }

    function CalcAttachFacing(target, pointer) {
        if (pointer==0)
            return Object.Facing(target);
        return Object.Facing(pointer);
    }

    function DoPossess(target) {
        local oldTarget = GetPossessedTarget();
        if (target==oldTarget)
            return;
        if (oldTarget!=0) {
            ClearData("IsPossessing");
            Detach(oldTarget);
            SendMessage(oldTarget, "NowDispossessed");
            // PhysAttach links don't like being destroyed and recreated in
            // the same frame. So try again next frame.
            PostMessage(self, "Possess", target);
            return;
        }
        SetData("IsPossessing", 1);
        Attach(target, AttachOffset(target));
        // TODO: update facing if needed?
        //local facing = CalcAttachFacing(target, pointer);

        TriggerFlash("PossessFlash");

        local reply = SendMessage(target, "NowPossessed");
        if (reply=="Mobile") {
            // Update attachment position every frame for a mobile possessable.
            PostMessage(self, "PossessUpdate");
        }
    }

    function DoDispossess(target) {
        if (target!=null && target!=0) {
            // Only disconnect from specific target.
            local oldTarget = GetPossessedTarget();
            if (target!=oldTarget)
                return;
        }
        ClearData("IsPossessing");
        Detach(target);
        SendMessage(target, "NowDispossessed");
    }

    function GetPossessedTarget() {
        local link = Link.GetOne("PhysAttach", self);
        if (link==0)
            return 0;
        link = Link.GetOne("Population", LinkDest(link));
        if (link==0)
            return 0;
        return LinkDest(link);
    }

    function Attach(target, offset) {
        local pos = Object.Position(target); // TODO: pointer pos + camera offset
        SetAnchorPosition(pos);
        local anchor = GetPossessAnchor();
        // Clear the player's collision response so they won't impact doors, AIs, etc.
        local collisionType = GetProperty("CollisionType");
        SetData("PlayerCollisionType", GetProperty("CollisionType"));
        SetData("PlayerRadius1", GetProperty("PhysDims", "Radius 1"));
        SetData("PlayerRadius2", GetProperty("PhysDims", "Radius 2"));
        SetProperty("CollisionType", 0);
        SetProperty("PhysDims", "Radius 1", 0.01);
        SetProperty("PhysDims", "Radius 2", 0.01);
        // NOTE: Awareness links will be snapped by the teleport. However,
        //       without the teleport the player is pulled at high speed to
        //       the attach position, with their camera doing the whole
        //       leaning-backward thing; and will also fly right through
        //       solid terrain, which is perhaps undesirable.
        // NOTE: The fly-to-target is very cool, but only works sometimes;
        //       e.g. when possessing the door, we just sit where we were until
        //       we try to crouch, and only then fly in. So, if we want the
        //       fly-in, we should probably do it manually with a projectile.
        local pointer = FindPossessPoint(target);
        local facing = Object.Facing((pointer!=0)? pointer : target);
        Object.Teleport(self, vector(), facing, anchor);
        local link = Link.Create("PhysAttach", self, anchor);
        LinkTools.LinkSetData(link, "Offset", offset);
        Link.Create("Population", anchor, target);
    }

    function Detach(target) {
        local anchor = GetPossessAnchor();
        Link.Destroy(Link.GetOne("PhysAttach", self, anchor));
        Link.Destroy(Link.GetOne("Population", anchor, target));
        Property.Set(anchor, "MovingTerrain", "Active", false);
        // Restore the player's collision response.
        SetProperty("CollisionType", GetData("PlayerCollisionType"));
        SetProperty("PhysDims", "Radius 1", GetData("PlayerRadius1"));
        SetProperty("PhysDims", "Radius 2", GetData("PlayerRadius2"));
    }

    function UpdateAttachPosition() {
        local target = GetPossessedTarget();
        local pos = Object.Position(target); // TODO: pointer pos + camera offset
        SetAnchorPosition(pos);
        local link = Link.GetOne("PhysAttach", self);
        if (link!=0)
            LinkTools.LinkSetData(link, "Offset", AttachOffset(target));
    }

    function SetAnchorPosition(posWorldSpace) {
        local anchor = GetPossessAnchor();
        local terrpt1 = GetTerrPt1(anchor);
        local terrpt2 = GetTerrPt2(terrpt1);
        Object.Teleport(anchor, posWorldSpace, vector(45,0,0));
        Object.Teleport(terrpt1, vector(), vector(), anchor);
        Object.Teleport(terrpt2, vector(0,0,4), vector(), anchor);
    }

    function TriggerFlash(flashArch) {
        // NOTE: Using DrkPowerups.TriggerWorldFlash() is fraught because it
        //       requires the player to be looking at a thing for them to
        //       see it. Instead we use the same technique here as in
        //       tnhScript's TrapRenderFlash, leaning on the player-only
        //       flash when the camera is attached to something, and immediately
        //       returning the camera again. Note that this looks for a
        //       RenderFlash link from the archetype, not the object itself;
        //       so we have to swizzle the links around if there is one there
        //       already (e.g. the T2 default for CamGrenades).
        //       As noted in tnhScript, this has the side effect of deselecting
        //       any weapon the player is holding; but since our spellcaster
        //       will force reselection of itself, that is not a concern.
        local player = Object.Named("Player");
        local arch = Object.Archetype(player);
        local oldFlash = 0;
        local link = Link.GetOne("RenderFlash", arch);
        if (link!=0) {
            oldFlash = LinkDest(link);
            Link.Destroy(link);
        }
        link = Link.Create("RenderFlash", arch, flashArch);
        Camera.StaticAttach(self);
        Camera.CameraReturn(self);
        Link.Destroy(link);
        if (oldFlash!=0)
            Link.Create("RenderFlash", arch, oldFlash);
    }
}

class Possessable extends SqRootScript {
    function GetPossessPoint() {
        foreach (link in Link.GetAll("~DetailAttachement", self)) {
            if (Object.InheritsFrom(LinkDest(link), "PossessPoint")) {
                return LinkDest(link);
            }
        }
        return 0;
    }

    function OnGetPossessPoint() {
        Reply(GetPossessPoint());
    }

    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnPhysCollision() {
        local pt = GetPossessPoint();
        if (pt==0) {
            print("ERROR: Possessable "+desc(self)+" has no PossessPoint.");
            return;
        }
        local pos = Object.Position(pt);
        // I used to do this with stims, and still can if I could be
        // bothered to faff with Weak Point offsets. But then we would
        // still need the same offsets for camera attachment. So I can't
        // be bothered.
        if (message().collType==ePhysCollisionType.kCollObject
        && Object.InheritsFrom(message().collObj, "PossessShot")) {
            // Make sure the shot was accurate, i.e. it hit within a
            // cylinder along the shot path with radius POSSESS_POINT_RADIUS.
            local collPos = message().collPt;
            local collNorm = message().collNormal.GetNormalized();
            local t = (pos-collPos).Dot(collNorm);
            local nearest = collPos+(collNorm*t);
            local dist = (pos-nearest).Length();
            if (dist<=POSSESS_POINT_RADIUS) {
                PostMessage("Player", "Possess", self);
            }
        }
    }

    function OnNowPossessed() {
        if (! Object.HasMetaProperty(self, "M-NoFrobWhilePossessed"))
            Object.AddMetaProperty(self, "M-NoFrobWhilePossessed");
    }

    function OnNowDispossessed() {
        Object.RemoveMetaProperty(self, "M-NoFrobWhilePossessed");
    }
}

class PossessableMobile extends SqRootScript {
    function OnNowPossessed() {
        Reply("Mobile");
    }
}

class PossessPoint extends SqRootScript {
    function OnTurnOn() {
        local player = Object.Named("Player");
        local link = Link.GetOne("DetailAttachement", self);
        if (link==0)
            return;
        SendMessage(player, "Possess", LinkDest(link));
    }

    function OnTurnOff() {
        local player = Object.Named("Player");
        local link = Link.GetOne("DetailAttachement", self);
        if (link==0)
            return;
        SendMessage(player, "Dispossess", LinkDest(link));
    }
}

class DebugViewmodelTweaker extends SqRootScript {
    function OnFrobWorldBegin() {
        local animS = GetProperty("StTweqJoints", "AnimS");
        animS = animS|1; // on
        SetProperty("StTweqJoints", "AnimS", animS);
        SetData("Adjusting", 1);
        PostMessage(self, "AdjustTick");
    }

    function OnFrobWorldEnd() {
        local animS = GetProperty("StTweqJoints", "AnimS");
        animS = animS&~1; // off
        local value = GetProperty("JointPos", "Joint 1");
        local range = GetProperty("CfgTweqJoints", "    rate-low-high");
        if (value>range.y && value<range.z) {
            animS = animS^2; // toggle reverse
        }
        SetProperty("StTweqJoints", "AnimS", animS);
        ClearData("Adjusting");
        PrepareUpdate();
    }

    function OnAdjustTick() {
        if (IsDataSet("Adjusting")) {
            PrepareUpdate();
            PostMessage(self, "AdjustTick");
        }
    }

    function PrepareUpdate() {
        local value = GetProperty("JointPos", "Joint 1");
        local range = GetProperty("CfgTweqJoints", "    rate-low-high");
        value = (value-range.y)/(range.z-range.y);
        value = GetValue(value);
        local message = VarName()+": "+value;
        print(message);
        DarkUI.TextMessage(message, 0);
        Update(value);
        UpdateViewmodel();
    }

    function UpdateViewmodel() {
        local arm = Object.Named("PlyrArm");
        if (arm==0) {
            print("no arm");
            return;
        }
        local link = Link.GetOne("~DetailAttachement", arm);
        if (link==0) {
            print("no viewmodel");
            return;
        }
        local pos = g_ViewmodelPos;
        local fac = g_ViewmodelFac;
        LinkTools.LinkSetData(link, "rel pos", pos);
        LinkTools.LinkSetData(link, "rel rot", fac);
    }

    function VarName() { return "(unset)"; }
    function GetValue(raw) { return raw; }
    function Update(value) {}
}

class DebugPosX extends DebugViewmodelTweaker {
    function VarName() { return "pos.x"; }
    function GetValue(raw) { return 2.0*raw-1.0; }
    function Update(value) { g_ViewmodelPos.x = value; }
}
class DebugPosY extends DebugViewmodelTweaker {
    function VarName() { return "pos.y"; }
    function GetValue(raw) { return 2.0*raw-1.0; }
    function Update(value) { g_ViewmodelPos.y = value; }
}
class DebugPosZ extends DebugViewmodelTweaker {
    function VarName() { return "pos.z"; }
    function GetValue(raw) { return 2.0*raw-1.0; }
    function Update(value) { g_ViewmodelPos.z = value; }
}
class DebugFacX extends DebugViewmodelTweaker {
    function VarName() { return "fac.x"; }
    function GetValue(raw) { return raw*360.0-180.0; }
    function Update(value) { g_ViewmodelFac.x = value; }
}
class DebugFacY extends DebugViewmodelTweaker {
    function VarName() { return "fac.y"; }
    function GetValue(raw) { return raw*360.0-180.0; }
    function Update(value) { g_ViewmodelFac.y = value; }
}
class DebugFacZ extends DebugViewmodelTweaker {
    function VarName() { return "fac.z"; }
    function GetValue(raw) { return raw*360.0; }
    function Update(value) { g_ViewmodelFac.z = value; }
}


class PossessCaster extends SqRootScript {
    function OnContained() {
        if (message().event==eContainsEvent.kContainAdd) {
            // Make sure we are selected immediately.
            DarkUI.InvSelect(self);
        } else if (message().event==eContainsEvent.kContainRemove) {

        }
    }

    function OnFrobInvBegin() {
        // Player left-clicked while possessed.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        if (message().Abort) {
            ClearData("CastStart");
            StopCrosshair();
        } else {
            SetData("CastStart", GetTime());
            StartCrosshair();
        }

    }

    function OnFrobInvEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        if (IsDataSet("CastStart")) {
            local startTime = GetData("CastStart");
            ClearData("CastStart");
            StopCrosshair();
            local elapsed = GetTime()-startTime;
            print("Cast elapsed:"+elapsed);
            if (elapsed>=g_minCastTime) {
                CastSpell();
            }
        }
    }

    function OnInvSelect() {
        if (USE_VIEWMODEL) {
            if (USE_PLAYERLIMBS_API) {
                // NOTE: using PlayerLimbs.Equip() is hardcoded to always apply the
                //       "carrying body" lowered head position. But for this mission
                //       we dont care; the player is basically disembodied the whole
                //       time they have this item equipped anyway.
                PlayerLimbs.Equip(self);
            } else {
                // NOTE: using Weapon.Equip() is hardcoded to play either the sword
                //       or, if the weapon type is 1, blackjack sounds when equipping
                //       and unequipping.
                Weapon.Equip(self, 1);
            }
            AttachViewmodel();
        }
    }

    function OnInvDeSelect() {
        if (USE_VIEWMODEL) {
            DetachViewmodel();
            if (USE_PLAYERLIMBS_API) {
                PlayerLimbs.UnEquip(self);
            } else {
                Weapon.UnEquip(self);
            }
        }
        if (PREVENT_DESELECT) {
            // Prevent from being deselected in inventory.
            // NOTE: neither DarkUI.InvSelect(self) nor the inv_select command works
            //       to prevent the weapon from being deselected! So we post a
            //       message to force a reselection next frame.
            PostMessage(self, "ForceReselect");
        }
    }

    function OnForceReselect() {
        DarkUI.InvSelect(self);
    }

    function OnTryAttach() {
        // BUG: if we cycle from sword to our weapon quickly, the PlyrArm
        //      exists already on try 0, but we then _dont_ successfully spawn
        //      the viewmodel, or something? investigate.
        if (IsDataSet("AttachTry")) {
            local attempt = GetData("AttachTry");
            print("TryAttach: "+attempt);
            if (attempt<60) {
                local arm = Object.Named("PlyrArm");
                if (arm==0) {
                    SetData("AttachTry", attempt+1);
                    PostMessage(self, "TryAttach");
                } else {
                    ClearData("AttachTry");
                    SpawnViewmodel(arm);
                }
            } else {
                ClearData("AttachTry");
            }
        }
    }

    function AttachViewmodel() {
        if (GetViewmodel()==0) {
            if (! IsDataSet("AttachTry")) {
                // PlyrArm is not immediately available, so try each frame to find it.
                SetData("AttachTry", 0);
                OnTryAttach();
            }
        }
    }

    function DetachViewmodel() {
        // The PlyrArm is destroyed, so detail-attached objects will be
        // destroyed with it. So just make sure we abort finding the PlyrArm
        // if we have not yet found it.
        ClearData("AttachTry");
    }

    function GetViewmodel() {
        foreach (link in Link.GetAll("ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="PossessVM") {
                return LinkDest(link);
            }
        }
        return 0;
    }

    function GetCrosshair1() {
        foreach (link in Link.GetAll("ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="PossessCH1") {
                return LinkDest(link);
            }
        }
        return 0;
    }

    function GetCrosshair2() {
        foreach (link in Link.GetAll("ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="PossessCH2") {
                return LinkDest(link);
            }
        }
        return 0;
    }

    function SpawnViewmodel(arm) {
        local archName = "PossessCasterVM";
        local arch = Object.Named(archName);
        if (arch==0) {
            print("ERROR: no archetype named '"+archName+"'");
            return 0;
        }
        local viewmodel = Object.BeginCreate(arch);
        Property.SetSimple(viewmodel, "Transient", true);
        Object.EndCreate(viewmodel);
        local link = Link.Create("ScriptParams", self, viewmodel);
        LinkTools.LinkSetData(link, "", "PossessVM");
        link = Link.Create("DetailAttachement", viewmodel, arm);
        LinkTools.LinkSetData(link, "Type", 2); // Joint
        LinkTools.LinkSetData(link, "joint", 1);
        LinkTools.LinkSetData(link, "rel pos", g_ViewmodelPos);
        LinkTools.LinkSetData(link, "rel rot", g_ViewmodelFac);

        local crosshair1 = 0;
        local crosshair2 = 0;
        foreach  (link in Link.GetAll("~DetailAttachement", viewmodel)) {
            local o = LinkDest(link);
            // NOTE: PossessCrosshair2 itself inherits from PossessCrosshair,
            //       so we must check for it first.
            if (Object.InheritsFrom(o, "PossessCrosshair2"))
                crosshair2 = o;
            else if (Object.InheritsFrom(o, "PossessCrosshair"))
                crosshair1 = o;
        }
        if (crosshair1==0 || crosshair2==0) {
            print("WARNING: no crosshair attached to viewmodel.");
            return 0;
        }
        link = Link.Create("ScriptParams", self, crosshair1);
        LinkTools.LinkSetData(link, "", "PossessCH1");
        link = Link.Create("ScriptParams", self, crosshair2);
        LinkTools.LinkSetData(link, "", "PossessCH2");
    }

    function _StartCrosshairTweq(crosshair) {
        if (crosshair==0) {
            print("WARNING: no crosshair to tweq.");
            return;
        }
        // Start the shrinking tweq.
        local params = Property.Get(crosshair, "CfgTweqScale", "x rate-low-high");
        Property.SetSimple(crosshair, "Scale", vector(params.z,params.z,params.z));
        Property.Set(crosshair, "StTweqScale", "AnimS", 3); // On|Reverse
        Property.Set(crosshair, "StTweqScale", "Axis 1AnimS", 3); // On|Reverse
        Property.Set(crosshair, "StTweqScale", "Axis 2AnimS", 3); // On|Reverse
        Property.Set(crosshair, "StTweqScale", "Axis 3AnimS", 3); // On|Reverse
        Property.SetSimple(crosshair, "RenderType", 2); // Unlit
    }

    function _StopCrosshairTweq(crosshair) {
        if (crosshair==0) {
            print("WARNING: no crosshair to tweq.");
            return;
        }
        // Stop the tweq.
        Property.Set(crosshair, "StTweqScale", "AnimS", 0);
        Property.SetSimple(crosshair, "RenderType", 1); // Not Rendered
    }

    function StartCrosshair() {
        _StartCrosshairTweq(GetCrosshair1());
        _StartCrosshairTweq(GetCrosshair2());
    }

    function StopCrosshair() {
        _StopCrosshairTweq(GetCrosshair1());
        _StopCrosshairTweq(GetCrosshair2());
    }

    function CastSpell() {
        local viewmodel = USE_VIEWMODEL? GetViewmodel() : Object.Named("Player");
        if (viewmodel==0) {
            print("WARNING: tried to cast spell when there is no viewmodel.");
            return;
        }
        // We could use a vhot in the model to mark the firing point, and
        // calculate the pos with Object.CalcRelTransform(), but since the
        // viewmodel is _probably_ going to have to be a mesh to have the
        // bow-zoom, and meshes can't have vhots, maybe there's no point.
        local o = Object.Create("PossessSpell");
        Object.Teleport(o, vector(0.588,0.025,0.125), vector(), viewmodel);
    }


/* TODO: restore or delete this idc
    function OnMessage() {
        // TEMP: print all other messages we might need to handle.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }
*/
}

class PossessViewmodel extends SqRootScript {
    function OnMessage() {
        // TEMP: print all other messages we might need to handle.
        print("PossessViewmodel - "+GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }
}

class PossessCrosshair extends SqRootScript {
    function OnTweqComplete() {
        // NOTE: Scale tweq does not always hit the endpoint when running,
        //       so we manually force the final scale here when the scale
        //       stops. Otherwise we would get an inconsistent crosshair size!
        if (message().Type==eTweqType.kTweqTypeScale
        && message().Op==eTweqOperation.kTweqOpHaltTweq) {
            local params = Property.Get(self, "CfgTweqScale", "x rate-low-high");
            Property.SetSimple(self, "Scale", vector(params.y,params.y,params.y));
        }
    }
}
