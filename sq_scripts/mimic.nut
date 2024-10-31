// TODO: clean up all the obsolete shit!!!

/* EMBODIMENT TYPES:

Camera.StaticAttach
-------------------
    - cannot turn camera
    - left or right click returns
    = camera overlay forced (customizable)
    - extreme FOV forced

Camera.DynamicAttach
--------------------
    + can rotate camera freely
    - left or right click returns
    = camera overlay forced (customizable)
    - extreme FOV forced

PhysAttach
----------
    = requires target to have physics
    - can only rotate camera horizontally?
    = no overlay
    = no fov change
    - maybe problems if player is close to terrain?

*/


/* TODO

    i think i can rewrite this to be more robust!
    idea (not originally mine) is to PhysAttach the player to
    a MovingTerrain with a self-linked TerrPt (speed 0?).

    we can then move the TerrPt around maybe?
    or DetailAttach the TerrPt to a door??

    idk more investigation needed.

    also want to get the offset done with a PossessPoint
    DetailAttached to archetypes.

    also want to have eye particle effects ParticleAttached
    to archetypes.
*/

/* Objects involved in possession:

     - Target: The object to be possessed, in the player's understanding. The
       target must have M-PossessMe or M-PossessMeMovable, and a
       ~DetailAttachement link from the Pointer (these may be configured on
       the target's archetype or on the target concrete itself).
       A target should also have a ~DetailAttachement or ~ParticleAttachement
       link from the Eyes.

     - Pointer: An instance of PossessPoint that marks where the camera should
       go. The Pointer also detects the stim when the player casts the possess
       spell.

     - Eyes: When turned off, a visual indication of where the possess spell
       should be cast to, and when turned on visual feedback of a possession
       about to happen.

           +---+
           |Tar| <-DA-- [Pointer]
           |get|
           |   | <-DA/PA-- [Eyes]
           |   |
           |   |
           +---+
*/

const USE_VIEWMODEL = true;
const USE_PLAYERLIMBS_API = true;
const PREVENT_DESELECT = true;

// NOTE: The player arm joint 1 position and orientation differs when using
//       PlayerLimbs vs Weapon (presumably due to the motions used). If we used
//       a custom mesh and custom motions, we could presumably nullify that;
//       but we have the stock meshes and motions, so we need to account for it.
//       These globals allow the viewmodel placement to be tweaked by hand in
//       the test mission.
local g_ViewmodelPos, g_ViewmodelFac;
if (USE_PLAYERLIMBS_API) {
    g_ViewmodelPos = vector(-0.0246241,-0.428078,-0.527131);
    g_ViewmodelFac = vector(0,0,149);
} else {
    g_ViewmodelPos = vector(0.2,0.2,2.0);
    g_ViewmodelFac = vector(0.0,0.0,0.0);
}


/* Converts TurnOn/TurnOff into possession/dispossession of the CD-linked
 * object, or self if there is no outgoing CD link. */
class TrapPossess extends SqRootScript {
    function OnTurnOn() {
        print(self+": "+message().message+" from:"+message().from);
        local player = Object.Named("Player");
        local link = Link.GetOne("ControlDevice", self);
        local target = (link!=0)? LinkDest(link) : self;
        print("target:"+target);
        SendMessage(player, "Possess", target);
    }

    function OnTurnOff() {
        print(self+": "+message().message+" from:"+message().from);
        local player = Object.Named("Player");
        local link = Link.GetOne("ControlDevice", self);
        local target = (link!=0)? LinkDest(link) : self;
        print("target:"+target);
        SendMessage(player, "Dispossess", target);
    }
}

class Possessor extends SqRootScript {
    // Possess: sent from anything, asks to begin possessing the 'data' object.
    function OnPossess() {
        print(self+": "+message().message+" from:"+message().from+" data:"+message().data);
        local target = message().data.tointeger();
        DoPossess(target);
    }

    // Dispossess: sent from anything, asks to stop possessing the 'data' object.
    // Has no effect if the player is not already doing so.
    function OnDispossess() {
        print(self+": "+message().message+" from:"+message().from+" data:"+message().data);
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
        foreach (link in Link.GetAll("~DetailAttachement", target)) {
            if (Object.InheritsFrom(LinkDest(link), "PossessPoint")) {
                return LinkDest(link);
            }
        }
        return 0;
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
        print("facing:" +facing);
        facing.x = 90;
        print("facing:" +facing);
        Object.Teleport(self, vector(), facing, anchor);
        local link = Link.Create("PhysAttach", self, anchor);
        LinkTools.LinkSetData(link, "Offset", offset);
        Link.Create("Population", anchor, target);
        // Clear the player's collision response so they won't impact doors, AIs, etc.
        local collisionType = GetProperty("CollisionType");
        SetData("PlayerCollisionType", collisionType);
        SetProperty("CollisionType", 0);
    }

    function Detach(target) {
        local anchor = GetPossessAnchor();
        Link.Destroy(Link.GetOne("PhysAttach", self, anchor));
        Link.Destroy(Link.GetOne("Population", anchor, target));
        Property.Set(anchor, "MovingTerrain", "Active", false);
        // Restore the player's collision response.
        local collisionType = GetData("PlayerCollisionType");
        SetProperty("CollisionType", collisionType);
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


class Foo {
    // Create/update/destroy the possess attachment:

    // PossessAttach: sent from the player. Create the objects and links needed
    // for attachment. message().data must be a vector with the camera offset
    // relative to the player's origin.
    function OnPossessAttach() {
        print(self+": "+message().message);
        local from = message().from;
        local who = GetPossessor();
        if (who==from) {
            // Already possessed by this player. Do nothing.
            Reply(true);
            return;
        } else if (who!=0) {
            // Possessed by something else? Disallow.
            print("ERROR: already possessed.");
            Reply(false);
            return;
        } else {
            // like, really the possessor should be managing the possess links and state!
            // all that the possessable needs to do is report the position of its
            // pointer, if it needs regular updates, and do door hacks.
        }
        local link = Link.GetOne("Population", self);
        if (link!=0) {

            Detach(player);
            print("ERROR: already attach.");
            Reply(false);
            return;
        }

        local cameraOffset = (message().data instanceof vector)? message().data:vector();
        SetData("CameraOffset", cameraOffset);
        local attachOffset = CalcAttachOffset(cameraOffset);
        local attachFacing = CalcAttachFacing();
        local ok = Attach(player, attachOffset, attachFacing);
        if (! ok) {
            print("ERROR: cannot attach.");
            Reply(false);
            return;
        }
        UpdateAttach(player);
        Reply(true);
    }

    // PossessDetach: sent from the player. Unconditionally destroy the objects
    // and links for attachment.
    function OnPossessDetach() {
        print(self+": "+message().message);
        local player = Object.Named("Player");
        Detach(player);
    }

    // PossessUpdate: sent from ourselves to update the attachment link.
    function OnPossessUpdate() {
        print(self+": "+message().message);
        local player = Object.Named("Player");
        UpdateAttach(player);
    }

    // Internals:

    function GetPossessor() {
        local link = Link.GetOne("Population", self);
        if (link==0)
            return 0;
        return LinkDest(Link);
    }

    function CalcAttachOffset(cameraOffset) {
        local pointer = FindPointer();
        if (pointer==0) {
            print("ERROR: cannot find PossessPoint; attaching at origin.");
            return vector();
        }
        // PhysAttach offset is always in world space.
        return Object.ObjectToWorld(pointer, cameraOffset)-Object.Position(self);
    }

    function CalcAttachFacing() {
        local pointer = FindPointer();
        if (pointer==0)
            return Object.Facing(self);
        return Object.Facing(pointer);
    }

    function FindPointer() {
        foreach (link in Link.GetAll("~DetailAttachement", self)) {
            if (Object.InheritsFrom(LinkDest(link), "PossessPoint")) {
                return LinkDest(link);
            }
        }
        return 0;
    }

    function UpdateAttach(player) {
        local cameraOffset = GetData("CameraOffset");
        local attachOffset = CalcAttachOffset(cameraOffset);
        local link = GetAttachLink(player);
        if (link==0)
            return;
        LinkTools.LinkSetData(link, "Offset", attachOffset);
        if (NeedsUpdateAttach()) {
            PostMessage(self, "PossessUpdate");
        }
    }

    // For subclasses to implement:
    function Attach(player, attachOffset, attachFacing) { return false; }
    function Detach(player) {}
    function GetAttachLink(player) { return 0; }
    function NeedsUpdateAttach() { return false; }
}

class Possessable extends SqRootScript {
    function OnPossessStimStimulus() {
        if (message().intensity>0) {
            local player = Object.Named("Player");
            SendMessage(player, "Possess", self);
        }
    }

    // function OnNowPossessed() {
    // }

    /*
    function Attach(player, attachOffset, attachFacing) {
        // We create a MovingTerrain that the player will be attached to, along
        // with points for a minimal path.
        local anchor = CreateAnchor();
        local terrpt1 = CreateTerrPt(vector());
        local terrpt2 = CreateTerrPt(vector(0,0,1));
        local link;
        Link.Create("Owns", self, anchor);
        Link.Create("Owns", self, terrpt1);
        Link.Create("Owns", self, terrpt2);
        // Create the links for the MovingTerrain and its path.
        Link.Create("TPathInit", anchor, terrpt1);
        link = Link.Create("TPath", terrpt1, terrpt2);
        LinkTools.LinkSetData(link, "Speed", 0.0);
        LinkTools.LinkSetData(link, "Pause (ms)", 0);
        LinkTools.LinkSetData(link, "Path Limit?", true);
        link = Link.Create("~TPath", terrpt1, terrpt2);
        LinkTools.LinkSetData(link, "Speed", 0.0);
        LinkTools.LinkSetData(link, "Pause (ms)", 0);
        LinkTools.LinkSetData(link, "Path Limit?", true);
        // Set things in motion (though it will not actually move, of course).
        Property.Set(anchor, "MovingTerrain", "Active", true);
        // Finally, attach the player to the anchor.
        Object.Teleport(player, vector(), vector(), anchor);
        link = Link.Create("PhysAttach", player, anchor);
        LinkTools.LinkSetData(link, "Offset", attachOffset);
        // TODO: send initial facing to the player?
        return true;
    }

    function Detach(player) {
        // NOTE: PhysAttach links must be destroyed before their target,
        //       otherwise the player will still be unable to move.
        local link = GetAttachLink(player);
        if (link!=0)
            Link.Destroy(link);
        // Clean up the MovingTerrain and its TerrPts.
        local objs = [];
        foreach (link in Link.GetAll("Owns", self)) {
            objs.append(LinkDest(link));
        }
        foreach (o in objs) {
            Object.Destroy(o);
        }
    }

    function GetAttachLink(player) {
        local objs = [];
        foreach (link in Link.GetAll("Owns", self)) {
            objs.append(LinkDest(link));
        }
        foreach (o in objs) {
            local link = Link.GetOne("PhysAttach", player, o);
            if (link!=0)
                return link;
        }
        return 0;
    }

    // Internals:

    function CreateAnchor() {
        local o = Object.BeginCreate("Marker");
        Object.Teleport(o, vector(), vector(), self);
        Property.Set(o, "PhysType", "Type", 0); // OBB
        Property.Set(o, "PhysType", "# Submodels", 1);
        Property.Set(o, "PhysDims", "Size", vector());
        Property.Set(o, "PhysControl", "Controls Active", 8|16); // Location|Rotation
        Property.SetSimple(o, "CollisionType", 0); // No collision
        Property.SetSimple(o, "PhysCanMant", false);
        Property.SetSimple(o, "PhysAIColl", false);
        Object.EndCreate(o);
        return o;
    }

    function CreateTerrPt(offset) {
        local o = Object.BeginCreate("Marker");
        Object.Teleport(o, offset, vector(), self);
        Object.EndCreate(o);
        return o;
    }
*/
}

class PossessableMobile extends SqRootScript {
    function OnNowPossessed() {
        Reply("Mobile");
    }
/*
    function Attach(player, attachOffset, attachFacing) { return false; }
    function Detach(player) {}
    function NeedsUpdateAttach() { return true; }
*/
}

class PossessPoint extends SqRootScript {
    // TODO: detect a possession spell stim.

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
            // Create
            // Make sure we are selected immediately.
            DarkUI.InvSelect(self);
        } else if (message().event==eContainsEvent.kContainRemove) {

        }
    }

    function OnFrobInvBegin() {
        // Player left-clicked while possessed.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        if (message().Abort) {
            SendMessage("Player", "FrobLeftAbort");
        } else {
            SendMessage("Player", "FrobLeftBegin");
        }
    }

    function OnFrobInvEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        SendMessage("Player", "FrobLeftEnd");

        // TODO: dont allow spamming this
        CastSpell();
    }

    function OnInvSelect() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
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
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
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
            if (attempt<60) {
                local arm = Object.Named("PlyrArm");
                print("Try "+attempt+" PlyrArm:"+arm+" named:"+(arm==0? "" : Object.GetName(arm)));
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

    function SpawnViewmodel(arm) {
        local archName = "PossessCasterVM";
        local arch = Object.Named(archName);
        if (arch==0) {
            print("ERROR: no archetype named '"+archName+"'");
            return 0;
        }
        local viewmodel = Object.BeginCreate(arch);
        Property.SetSimple(viewmodel, "Transient", true);
        Object.Teleport(viewmodel, vector(), vector());
        Object.EndCreate(viewmodel);
        local link = Link.Create("DetailAttachement", viewmodel, arm);
        LinkTools.LinkSetData(link, "Type", 2); // Joint
        LinkTools.LinkSetData(link, "joint", 1);
        LinkTools.LinkSetData(link, "rel pos", g_ViewmodelPos);
        LinkTools.LinkSetData(link, "rel rot", g_ViewmodelFac);
        link = Link.Create("ScriptParams", self, viewmodel);
        LinkTools.LinkSetData(link, "", "PossessVM");

        if(0) {
            // okay, create two more for blender's sake
            local spawnCube = function(pos, atJoint) {
                local v = Object.BeginCreate(arch);
                Property.SetSimple(v, "Transient", true);
                Object.Teleport(v, vector(), vector());
                Object.EndCreate(v);
                local link = Link.Create("DetailAttachement", v, arm);
                if (atJoint) {
                    LinkTools.LinkSetData(link, "Type", 2); // Joint
                    LinkTools.LinkSetData(link, "joint", 1);
                } else {
                    LinkTools.LinkSetData(link, "Type", 0); // Object
                }
                LinkTools.LinkSetData(link, "rel pos", pos);
                LinkTools.LinkSetData(link, "rel rot", vector());
            }
            spawnCube(vector(0.0,0.0,0.0), false);
            spawnCube(vector(-0.5,0.0,0.0), true);
            spawnCube(vector(-1.0,0.0,0.0), true);
            spawnCube(vector(-1.5,0.0,0.0), true);
            spawnCube(vector(-2.0,0.0,0.0), true);
        }
        return viewmodel;
    }

    function CastSpell() {
        local viewmodel = USE_VIEWMODEL? GetViewmodel() : Object.Named("Player");
        if (viewmodel==0) {
            print("WARNING: tried to cast spell when there is no viewmodel.");
            return;
        }
        Physics.LaunchProjectile(viewmodel, "PossessSpell", 1.0, 2|8, vector()); // PRJ_FLG_PUSHOUT|PRJ_FLG_GRAVITY
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

// TODO: obsolete
class OldPossessMe extends SqRootScript {
    function ParseVector(s) {
        local v = vector();
        local at = 0;
        local i = s.find(",", at);
        if (i == null) throw("must be a vector of 3 floats");
        v.x = (s.slice(at, i)).tofloat();
        at = i+1;
        i = s.find(",", at);
        if (i == null) throw("must be a vector of 3 floats");
        v.y = (s.slice(at, i)).tofloat();
        at = i+1;
        v.z = (s.slice(at)).tofloat();
        return v;
    }

    function GetPossessOffset() {
        local params = userparams();
        local offset = vector();
        if ("PossessOffset" in params) {
            offset = ParseVector(params.PossessOffset);
        }
        return offset;
    }

    function OnFrobWorldEnd() {
        local frobber = message().Frobber;
        if (Object.InheritsFrom(frobber, "Avatar")) {
            BlockMessage();
            SendMessage(frobber, "PossessMe", GetPossessOffset());
        }
    }
}

Possess <- {
    // From PHYSAPI.H:
    PLAYER_HEAD = 0,
    PLAYER_FOOT = 1,
    PLAYER_BODY = 2,
    PLAYER_KNEE = 3,
    PLAYER_SHIN = 4,
    PLAYER_RADIUS = 1.2,
    PLAYER_HEIGHT = 6.0,

    // From PRJCTILE.H:
    PRJ_FLG_ZEROVEL = (1 << 0), // ignore launcher velocity
    PRJ_FLG_PUSHOUT = (1 << 1), // push away from launcher
    PRJ_FLG_FROMPOS = (1 << 2), // don't init position (only makes sense for concretes)
    PRJ_FLG_GRAVITY = (1 << 3), // object has gravity if default physics
    PRJ_FLG_BOWHACK = (1 << 8),  // do all bow hackery
    PRJ_FLG_TELLAI = (1 << 9),  // tell AIs about this object
    PRJ_FLG_NOPHYS = (1 <<10),  // create the object without adding physics
    PRJ_FLG_MASSIVE = (1 <<11),  // slow down the velocity based on  
    PRJ_FLG_NO_FIRER = (1<<12),  // don't creature firer link

    function GetAnchor() {
        return Object.Named("PossessAnchor");
    }

    function GetAnchorPointer() {
        return Object.Named("PossessAnchorPointer");
    }

    function GetWasAt() {
        return Object.Named("PossessWasAt");
    }

    function GetInventory() {
        return Object.Named("PossessInventory");
    }

    function GetFrobLeft() {
        return Object.Named("PossessFrobLeft");
    }

    function GetFrobRight() {
        return Object.Named("PossessFrobRight");
    }

    function GetGhost() {
        return Object.Named("PossessGhost");
    }

    function GetHeadProbe() {
        return Object.Named("PossessHeadProbe");
    }

    function GetBodyProbe() {
        return Object.Named("PossessBodyProbe");
    }

    function GetFootProbe() {
        return Object.Named("PossessFootProbe");
    }

    function GetPhysCastProjectile() {
        local proj = Object.Named("PossessPhysCastProj");
        if (proj==0) {
            proj = Object.BeginCreate("PossessPhysCastArch");
            Object.SetName(proj, "PossessPhysCastProj");
            // TODO: can i put Transient on the archetype?
            Property.SetSimple(proj, "Transient", true); // Will not be saved.

            // TODO: remove these:
            Property.SetSimple(proj, "RenderType", 2); // TEMP: Unlit
            Property.SetSimple(proj, "ModelName", "unitsfer"); // TEMP
            Property.SetSimple(proj, "Scale", vector(1,1,1)*0.125); // TEMP

            Object.EndCreate(proj);
        }
        return proj;
    }

    function CreateFnords() {
        local anchor = Possess.GetAnchor();
        if (anchor==0) {
            anchor = Object.BeginCreate("fnord");
            Object.SetName(anchor, "PossessAnchor");
            Object.Teleport(anchor, vector(), vector());
            Property.Set(anchor, "PhysType", "Type", 0); // OBB
            Property.Set(anchor, "PhysType", "# Submodels", 1);
            Property.Set(anchor, "PhysDims", "Size", vector());
            Property.Set(anchor, "PhysControl", "Controls Active", 8|16); // Location|Rotation
            Property.SetSimple(anchor, "CollisionType", 0); // No collision
            Property.SetSimple(anchor, "PhysCanMant", false);
            Property.SetSimple(anchor, "PhysAIColl", false);
            Object.EndCreate(anchor);
        }
        local anchorPointer = Possess.GetAnchorPointer();
        if (anchorPointer==0) {
            anchorPointer = Object.BeginCreate("fnord");
            Object.SetName(anchorPointer, "PossessAnchorPointer");
            Object.Teleport(anchorPointer, vector(), vector());
            Object.EndCreate(anchorPointer);
        }
        local wasAt = Possess.GetWasAt();
        if (wasAt==0) {
            wasAt = Object.BeginCreate("fnord");
            Object.SetName(wasAt, "PossessWasAt");
            Object.EndCreate(wasAt);
        }
        local inv = Possess.GetInventory();
        if (inv==0) {
            inv = Object.BeginCreate("fnord");
            Object.SetName(inv, "PossessInventory");
            Object.EndCreate(inv);
        }
        local frobLeft = Possess.GetFrobLeft();
        if (frobLeft==0) {
            frobLeft = Object.BeginCreate("fnord");
            Object.SetName(frobLeft, "PossessFrobLeft");
            Property.Set(frobLeft, "FrobInfo", "World Action", 2|16); // Script|FocusScript
            Property.Set(frobLeft, "FrobInfo", "Inv Action", 2|16); // Script|FocusScript
            Property.Set(frobLeft, "FrobInfo", "Tool Action", 2|16); // Script|FocusScript
            Property.SetSimple(frobLeft, "InvType", 2); // Weapon
            Property.SetSimple(frobLeft, "NoDrop", true);
            Property.Set(frobLeft, "Scripts", "Script 0", "PossessFrobLeft");
            // TODO: we don't want to render it like this, except for debug, right?
            // TODO: the resource doesn't load if we only set it at runtime like
            //       this! probably need an archetype with this property set.
            Property.Set(frobLeft, "InvRendType", "Resource", "webgar3");
            Property.Set(frobLeft, "InvRendType", "Type", "Alternate Bitmap");
            Object.EndCreate(frobLeft);
        }
        local frobRight = Possess.GetFrobRight();
        if (frobRight==0) {
            frobRight = Object.BeginCreate("fnord");
            Object.SetName(frobRight, "PossessFrobRight");
            Property.Set(frobRight, "FrobInfo", "World Action", 2|16); // Script|FocusScript
            Property.Set(frobRight, "FrobInfo", "Inv Action", 2|16); // Script|FocusScript
            Property.Set(frobRight, "FrobInfo", "Tool Action", 0); // [None]
            Property.SetSimple(frobRight, "InvType", 1); // Item
            Property.SetSimple(frobRight, "NoDrop", true);
            Property.Set(frobRight, "Scripts", "Script 0", "PossessFrobRight");
            // TODO: we don't want to render it like this, except for debug, right?
            // TODO: the resource doesn't load if we only set it at runtime like
            //       this! probably need an archetype with this property set.
            Property.Set(frobRight, "InvRendType", "Resource", "zombieca");
            Property.Set(frobRight, "InvRendType", "Type", "Alternate Bitmap");
            Object.EndCreate(frobRight);
        }
        local ghost = Possess.GetGhost();
        if (ghost==0) {
            ghost = Object.BeginCreate("fnord");
            Object.SetName(ghost, "PossessGhost");
            Property.SetSimple(ghost, "RenderType", 1); // Not Rendered
            Property.SetSimple(ghost, "ModelName", "playbox");
            Object.EndCreate(ghost);
        }
        local headProbe = Possess.GetHeadProbe();
        if (headProbe==0) {
            headProbe = Object.BeginCreate("fnord");
            Object.SetName(headProbe, "PossessHeadProbe");
            Property.Set(headProbe, "PhysType", "Type", 1);
            Property.Set(headProbe, "PhysType", "# Submodels", 1);
            Property.Set(headProbe, "PhysDims", "Radius 1", PLAYER_RADIUS);
            Property.Set(headProbe, "PhysDims", "Offset 1", vector(0.0, 0.0, 0.0));
            Property.SetSimple(headProbe, "CollisionType", 0); // None
            Property.SetSimple(headProbe, "PhysAIColl", false);
            Property.SetSimple(headProbe, "RenderType", 1); // Not Rendered
            Object.Teleport(headProbe, vector(0,0,0), vector(0,0,0), 0);
            Object.EndCreate(headProbe);
            Physics.ControlCurrentLocation(headProbe);
            Physics.ControlCurrentRotation(headProbe);
        }
        local bodyProbe = Possess.GetBodyProbe();
        if (bodyProbe==0) {
            bodyProbe = Object.BeginCreate("fnord");
            Object.SetName(bodyProbe, "PossessBodyProbe");
            Property.Set(bodyProbe, "PhysType", "Type", 1);
            Property.Set(bodyProbe, "PhysType", "# Submodels", 1);
            Property.Set(bodyProbe, "PhysDims", "Radius 1", PLAYER_RADIUS);
            Property.Set(bodyProbe, "PhysDims", "Offset 1", vector(0.0, 0.0, 0.0));
            Property.SetSimple(bodyProbe, "CollisionType", 0); // None
            Property.SetSimple(bodyProbe, "PhysAIColl", false);
            Property.SetSimple(bodyProbe, "RenderType", 1); // Not Rendered
            Object.Teleport(bodyProbe, vector(0,0,0), vector(0,0,0), 0);
            Object.EndCreate(bodyProbe);
            Physics.ControlCurrentLocation(bodyProbe);
            Physics.ControlCurrentRotation(bodyProbe);
        }
        local footProbe = Possess.GetFootProbe();
        if (footProbe==0) {
            footProbe = Object.BeginCreate("fnord");
            Object.SetName(footProbe, "PossessFootProbe");
            Property.Set(footProbe, "PhysType", "Type", 1);
            Property.Set(footProbe, "PhysType", "# Submodels", 1);
            Property.Set(footProbe, "PhysDims", "Radius 1", 0.0);
            Property.Set(footProbe, "PhysDims", "Offset 1", vector(0.0, 0.0, 0.0));
            Property.SetSimple(footProbe, "CollisionType", 0); // None
            Property.SetSimple(footProbe, "PhysAIColl", false);
            Property.SetSimple(footProbe, "RenderType", 1); // Not Rendered
            Object.Teleport(footProbe, vector(0,0,0), vector(0,0,0), 0);
            Object.EndCreate(footProbe);
            Physics.ControlCurrentLocation(footProbe);
            Physics.ControlCurrentRotation(footProbe);
        }
    }

    function LaunchProjectile(launcher, from, facing) {
        local proj = Possess.GetPhysCastProjectile();
        Object.Teleport(proj, from, facing);
        local launchedProj = Physics.LaunchProjectile(
            launcher,
            proj,
            0.1,
            PRJ_FLG_ZEROVEL|PRJ_FLG_FROMPOS|PRJ_FLG_NO_FIRER,//|PRJ_FLG_PUSHOUT
            vector());
        return proj;
    }
};

class OlderPossessor extends SqRootScript {
    function OnPossessMe() {
        print(self+": "+message().message);
        // TODO: manage possession state.
        // TODO: calculate the offset (playerHeadZ+0.8);
        SendMessage(message().from, "PossessAttach", vector());
    }

    function OnDispossessMe() {
        print(self+": "+message().message);
        // TODO: manage possession state.
        SendMessage(message().from, "PossessDetach");
    }
}

class OldPossessor extends SqRootScript {

    // NOTE: A "PhysCast" is carried out by launching an invisible projectile
    //       that, when it collides, will send the Player a PhysCastHit message.
    //       We can use squirrel member variables to keep track of the physcast
    //       state safely, because we do *not* want a physcast to persist over
    //       a save/load. The physcast projectile itself should be marked as
    //       transient so that it is not saved.
    // TODO: use this!
    m_awaitingPhysCastResult = false;

    function OnBeginScript() {
        if (Object.InheritsFrom(self, "Avatar")) {
            if (! IsDataSet("IsPossessing")) {
                SetData("IsPossessing", false);
            }
            if (! IsDataSet("IsTargeting")) {
                SetData("IsTargeting", false);
            }
            if (! IsDataSet("TargetingTimer")) {
                SetData("TargetingTimer", 0);
            }
            if (! IsDataSet("IsTargetValid")) {
                SetData("IsTargetValid", false);
            }
            if (! IsDataSet("TargetPosition")) {
                SetData("TargetPosition", vector());
            }
            if (! IsDataSet("TargetFacing")) {
                SetData("TargetFacing", vector());
            }
            if (! IsDataSet("PlayerHeadOffset")) {
                SetData("PlayerHeadOffset", vector());
            }
            if (! IsDataSet("PlayerBodyOffset")) {
                SetData("PlayerBodyOffset", vector());
            }
            if (! IsDataSet("PlayerFootOffset")) {
                SetData("PlayerFootOffset", vector());
            }
            Possess.CreateFnords();
        } else {
            // We are probably the starting point. Do nothing.
        }
    }

    function IsPossessing() {
        return (!! GetData("IsPossessing"));
    }

    function IsTargeting() {
        return (!! GetData("IsTargeting"));
    }

    function GetPossessedLink() {
        foreach (link in Link.GetAll("ScriptParams")) {
            if (LinkTools.LinkGetData(link, "")=="Possessed") {
                return link;
            }
        }
        return 0;
    }

    function GetPossessedObject() {
        local link = GetPossessedLink();
        if (link==0) return 0;
        return LinkDest(link);
    }

    function OnPossessMe() {
        if (IsPossessing()) {
            // TODO: support hopping from one possession to another?
            Reply(false);
            return;
        } else {
            local offset = message().data;
            if (offset==null) offset = vector();
            BeginPossession(message().from, offset);
        }
    }

    function OnExorcise() {
        if (IsPossessing()) {
            local wasAt = Possess.GetWasAt();
            EndPossession(Object.Position(wasAt), Object.Facing(wasAt));
        } else {
            Reply(false);
            return;
        }
    }

    function OnContainer() {
        if (IsPossessing()) {
            // If we pick up anything while possessed, send it to join the
            // rest of the player inventory. We don't normally expect this
            // to happen, as we are using M-NoFrobWhilePossessed to make all
            // the things unfrobbable. But maybe you want to disable that; or
            // maybe a script would have given you items; or maybe something
            // else. Let's just be robust here, shall we?
            local inv = Possess.GetInventory();
            local frobL = Possess.GetFrobLeft();
            local frobR = Possess.GetFrobRight();
            local what = message().containee;
            if (message().event==eContainsEvent.kContainAdd
            && what!=frobL && what!=frobR) {
                Container.Add(what, inv);
            }
        }
    }

    function OnFrobLeftBegin() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobLeftEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        Possess.LaunchProjectile(self, Camera.GetPosition(), Camera.GetFacing());
    }

    function OnFrobLeftAbort() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobRightBegin() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        BeginTargeting();
        if (! IsTargeting) {
            SetData("IsTargeting", true);
            // TODO: start raycasting every frame
        }
    }

    function OnFrobRightEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        EndTargeting(true);
    }

    function OnFrobRightAbort() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        EndTargeting(false);
    }

    function EnableLootSounds(enable) {
        // Requires 'lootsounds.nut' that defines the global EnableLootSounds()
        if (("EnableLootSounds") in getroottable()) {
            ::EnableLootSounds(enable);
        } else {
            print("Warning: global EnableLootSounds() not defined; loot sounds are going to happen.");
        }
    }

    function IsDoor(obj) {
        return (Property.Possessed(obj,"RotDoor")
            || Property.Possessed(obj,"TransDoor"));
    }

    function BeginPossession(target, offset) {
        if (IsPossessing()) {
            print("ERROR! Tried to possess when already possessing. Fix this bug!");
            return false;
        }
        if (Link.AnyExist("PhysAttach", self)) {
            print("ERROR! Tried to possess when PhysAttached. Fix this bug!");
            return false;
        }

        local anchor = Possess.GetAnchor();
        local pointer = Possess.GetAnchorPointer();
        local wasAt = Possess.GetWasAt();
        local inv = Possess.GetInventory();
        local frobL = Possess.GetFrobLeft();
        local frobR = Possess.GetFrobRight();

        if (Link.AnyExist("TPathInit", anchor)
        || Link.AnyExist("TPath", target)) {
            print("ERROR! Tried to possess when anchor already has path links. Fix this bug!");
            return false;
        }
        if (Property.Possessed(anchor, "MovingTerrain")) {
            print("ERROR! Tried to possess when anchor is already a MovingTerrain. Fix this bug!");
            return false;
        }

        // Replace inventory with left/right frobabbles.
        Object.Teleport(wasAt, vector(), vector(), self);
        Container.MoveAllContents(self, inv, CTF_NONE);
        Container.Add(frobL, self, 0, CTF_NONE);
//        Container.Add(frobR, self, 0, CTF_NONE);

        // NOTE: we set IsPossessing *after* inventory transfer, so that we can
        //       safely check it in Container messages.
        SetData("IsPossessing", true);
        // And keep track of what we are possessing.
        local link = Link.Create("ScriptParams", self, target);
        LinkTools.LinkSetData(link, "", "Possessed");

        // Get the player's head and body position relative to their origin.
        // Headbob and lean will affect this a little, but we are ignoring that.
        // The main thing is to properly handle standing vs crouched difference.
        // NOTE: CalcRelTransform() returns the position of the child object
        //       relative to the given submodel of the parent object; but we
        //       want the submodel position relative to the parent origin,
        //       which is the inverse; hence the negations.
        local submodelOffset = vector();
        local ignoreFacing = vector();
        Object.CalcRelTransform(self, self, submodelOffset, ignoreFacing, 4, Possess.PLAYER_HEAD); // RelSubPhysModel
        local playerHeadZ = -submodelOffset.z;
        Object.CalcRelTransform(self, self, submodelOffset, ignoreFacing, 4, Possess.PLAYER_BODY); // RelSubPhysModel
        local playerBodyZ = -submodelOffset.z;
        Object.CalcRelTransform(self, self, submodelOffset, ignoreFacing, 4, Possess.PLAYER_FOOT); // RelSubPhysModel
        local playerFootZ = -submodelOffset.z;
        // Store the head and body positions so we can restore them when unpossessing.
        SetData("PlayerHeadOffset", vector(0.0,0.0,playerHeadZ));
        SetData("PlayerBodyOffset", vector(0.0,0.0,playerBodyZ));
        SetData("PlayerFootOffset", vector(0.0,0.0,playerFootZ));
        // Clear the player's collision response so they won't impact doors, AIs, etc.
        local collisionType = GetProperty("CollisionType");
        SetData("PlayerCollisionType", collisionType);
        SetProperty("CollisionType", 0);

        // Set up the anchor as a moving terrain, with the target as its starting TerrPt.
        // NOTE: for this to work, we need to have two TerrPts (one will not suffice),
        //       and they need to not be at the same position. But the speed can be zero,
        //       so the MovingTerrain never actually moves. So here we use the target
        //       itself as one of the TerrPts, and the pointer as the other (cause it
        //       was handy).
        // NOTE: this approach isnt any good if the attach point itself has to move, as
        //       for example with a door.
        Object.Teleport(anchor, vector(), vector(), target);
        Object.Teleport(pointer, vector(1,0,0), vector(), target);
        link = Link.Create("TPathInit", anchor, target);
        //link = Link.Create("TPathNext", anchor, pointer);
        link = Link.Create("TPath", target, pointer);
        LinkTools.LinkSetData(link, "Speed", 0.0);
        LinkTools.LinkSetData(link, "Pause (ms)", 0);
        LinkTools.LinkSetData(link, "Path Limit?", true);
        link = Link.Create("~TPath", target, pointer);
        LinkTools.LinkSetData(link, "Speed", 0.0);
        LinkTools.LinkSetData(link, "Pause (ms)", 0);
        LinkTools.LinkSetData(link, "Path Limit?", true);
        Property.Set(anchor, "MovingTerrain", "Active", true);

        // And attach ourselves to the anchor.
        Object.Teleport(self, vector(), vector(), anchor);
        Link.Create("PhysAttach", self, anchor);

/*
        // NOTE: The camera position is not at the center of the player's head
        //       submodel, but 0.8 units higher ("eyeloc"). So we offset the
        //       camera down by the same amount to counteract this.
        offset.z -= playerHeadZ+0.8;
        local toPos = Object.ObjectToWorld(target, offset);
        local toFacing = Object.Facing(target);
        if (directAttachMode) {
            if (! Object.HasMetaProperty(target, "M-PossessMouselookFix")) {
                Object.AddMetaProperty(target, "M-PossessMouselookFix");
            }

            Object.Teleport(pointer, toPos, toFacing);
            local d = Link.Create("DetailAttachement", pointer, target);
            LinkTools.LinkSetData(d, "Type", 0); // Object
            LinkTools.LinkSetData(d, "rel pos", offset);
            LinkTools.LinkSetData(d, "Flags", 1); // No Auto-Delete

            // TODO: if we want a fade to black, we apparently need to start it
            //       before the teleport??? or maybe that is just a not-doing-it-
            //       via-script thing.
            Object.Teleport(self, vector(), vector(), pointer);
            Link.Create("PhysAttach", self, target);

            PostMessage(target, "PossessEnableFix", 1);
            PostMessage(self, "PossessReanchor");
        } else {
            if (! Object.HasMetaProperty(anchor, "M-PossessMouselookFix")) {
                Object.AddMetaProperty(anchor, "M-PossessMouselookFix");
            }
            Object.Teleport(anchor, toPos, toFacing);

            // TODO: if we want a fade to black, we apparently need to start it
            //       before the teleport??? or maybe that is just a not-doing-it-
            //       via-script thing.
            Object.Teleport(self, vector(), vector(), anchor);
            Link.Create("PhysAttach", self, anchor);
            PostMessage(anchor, "PossessEnableFix", 1);
        }
*/
        // NOTE: We prevent frobbing most objects while possessed by generously
        //       adding this metaproperty to all physical objects. This won't
        //       work for any objects in e.g. the fnord or SFX trees have been
        //       made frobbable; and it won't work for concrete objects with
        //       a direct FrobInfo property on them making them frobbable.
        //       Those must be avoided when using this script.
        // NOTE: The PossessFrobs are both fnords *and* have a direct FrobInfo
        //       property, so they will be unaffected, as they need to be.
        // NOTE: If we only need right-frob, then we can change PossessFrobRight
        //       to be a junk item, because *nothing* can be frobbed while
        //       holding a junk item.
//        Object.AddMetaPropertyToMany("M-NoFrobWhilePossessed", "@physical");

        // TEMP: we don't have a way to manually detach yet, so automate it.
        SetOneShotTimer("TempDetach", 5.0);
    }

    // function OnFoo() {
    //     local anchor = Possess.GetAnchor();
    //     Property.Set(anchor, "MovingTerrain", "Active", true);
    // }

    function EndPossession(position, facing) {
        if (! IsPossessing()) {
            print("ERROR! Tried to unpossess when not possessing. Fix this bug!");
            return false;
        }
        EndTargeting(false);
        // NOTE: we must clear IsPossessing *before* inventory restoration, so
        //       that we won't react to the Container messages.
        SetData("IsPossessing", false);
        local target = GetPossessedObject();
        local anchor = Possess.GetAnchor();
        local pointer = Possess.GetAnchorPointer();
        local wasAt = Possess.GetWasAt();
        local inv = Possess.GetInventory();
        local frobL = Possess.GetFrobLeft();
        local frobR = Possess.GetFrobRight();
        // Disconnect from the anchor (or target).
        local link = Link.GetOne("PhysAttach", self, anchor);
        if (link==0) {
            link = Link.GetOne("PhysAttach", self, target);
            if (link==0) {
                print("ERROR! Unpossessed when not PhysAttached. Fix this bug!");
            }
        }
        Link.Destroy(link);
        // Disconnect the anchor.
        Property.Set(anchor, "MovingTerrain", "Active", false);
        Property.Remove(anchor, "MovingTerrain");
        link = Link.GetOne("TPath", target, pointer);
        if (link!=0)
            Link.Destroy(link);
        link = Link.GetOne("~TPath", target, pointer);
        if (link!=0)
            Link.Destroy(link);
        link = Link.GetOne("TPathInit", anchor, target);
        if (link!=0)
            Link.Destroy(link);
        link = Link.GetOne("TPathNext", anchor, target);
        if (link!=0)
            Link.Destroy(link);
        // Disconnect from the possessed target.
        link = GetPossessedLink();
        if (link==0) {
            print("ERROR! Unpossessed with no ScriptParams('Possessed') link. Fix this bug!");
        }
        Link.Destroy(link);
        // Restore the player's collision response.
        local collisionType = GetData("PlayerCollisionType");
        SetProperty("CollisionType", collisionType);
        // Restore player position.
        Object.Teleport(self, position, facing);
        // Restore inventory, setting the global flag to prevent loot sounds.
        EnableLootSounds(false);
        Container.Remove(frobL, self);
        Container.Remove(frobR, self);
        // TODO: will need to suppress loot sounds... maybe by making a custom
        //       squirrel LootSounds to use in preference to gen's?
        Container.MoveAllContents(inv, self, CTF_NONE);
        EnableLootSounds(true);
        // Park the anchor back at the origin ready for next time.
        Object.Teleport(anchor, vector(), vector());
        // Restore frobs.
        Object.RemoveMetaPropertyFromMany("M-NoFrobWhilePossessed", "@physical");
    }

    function OldBeginPossession(target, offset) {
        if (IsPossessing()) {
            print("ERROR! Tried to possess when already possessing. Fix this bug!");
            return false;
        }
        if (Link.AnyExist("PhysAttach", self)) {
            print("ERROR! Tried to possess when PhysAttached. Fix this bug!");
            return false;
        }
        // We have two modes of operation. Normally we teleport the anchor into
        // the desired position, and then PhysAttach the player to that. But
        // because the PhysAttach offset is in world coordinates, when attached
        // to a door (or rotating object), we would not rotate with the target.
        //
        // So in these cases we PhysAttach directly to the target, and
        // DetailAttach the pointer to the target also. Then each frame we
        // measure the worldspace coordinates of the pointer and the target,
        // and use that to update the PhysAttach offset.
        local directAttachMode = IsDoor(target);

        local anchor = Possess.GetAnchor();
        local pointer = Possess.GetAnchorPointer();
        local wasAt = Possess.GetWasAt();
        local inv = Possess.GetInventory();
        local frobL = Possess.GetFrobLeft();
        local frobR = Possess.GetFrobRight();
        Object.Teleport(wasAt, vector(), vector(), self);
        Container.MoveAllContents(self, inv, CTF_NONE);
        Container.Add(frobL, self, 0, CTF_NONE);
//        Container.Add(frobR, self, 0, CTF_NONE);
        // NOTE: we set IsPossessing *after* inventory transfer, so that we can
        //       safely check it in Container messages.
        SetData("IsPossessing", true);

        // Get the player's head and body position relative to their origin.
        // Headbob and lean will affect this a little, but we are ignoring that.
        // The main thing is to properly handle standing vs crouched difference.
        // NOTE: CalcRelTransform() returns the position of the child object
        //       relative to the given submodel of the parent object; but we
        //       want the submodel position relative to the parent origin,
        //       which is the inverse; hence the negations.
        local submodelOffset = vector();
        local ignoreFacing = vector();
        Object.CalcRelTransform(self, self, submodelOffset, ignoreFacing, 4, Possess.PLAYER_HEAD); // RelSubPhysModel
        local playerHeadZ = -submodelOffset.z;
        Object.CalcRelTransform(self, self, submodelOffset, ignoreFacing, 4, Possess.PLAYER_BODY); // RelSubPhysModel
        local playerBodyZ = -submodelOffset.z;
        Object.CalcRelTransform(self, self, submodelOffset, ignoreFacing, 4, Possess.PLAYER_FOOT); // RelSubPhysModel
        local playerFootZ = -submodelOffset.z;
        // Store the head and body positions so we can restore them when unpossessing.
        SetData("PlayerHeadOffset", vector(0.0,0.0,playerHeadZ));
        SetData("PlayerBodyOffset", vector(0.0,0.0,playerBodyZ));
        SetData("PlayerFootOffset", vector(0.0,0.0,playerFootZ));
        // Clear the player's collision response so they won't impact doors, AIs, etc.
        local collisionType = GetProperty("CollisionType");
        SetData("PlayerCollisionType", collisionType);
        SetProperty("CollisionType", 0);

        // TODO: delete this crap
        //                                    // stand / crouch
        // print("playerHeadZ:"+playerHeadZ); // 1.7 / -0.23
        // print("playerBodyZ:"+playerBodyZ); // -0.6 / -0.6
        // print("playerFootZ:"+playerFootZ); // -3 / -3

        // NOTE: The camera position is not at the center of the player's head
        //       submodel, but 0.8 units higher ("eyeloc"). So we offset the
        //       camera down by the same amount to counteract this.
        offset.z -= playerHeadZ+0.8;
        local toPos = Object.ObjectToWorld(target, offset);
        local toFacing = Object.Facing(target);
        if (directAttachMode) {
            if (! Object.HasMetaProperty(target, "M-PossessMouselookFix")) {
                Object.AddMetaProperty(target, "M-PossessMouselookFix");
            }

            Object.Teleport(pointer, toPos, toFacing);
            local d = Link.Create("DetailAttachement", pointer, target);
            LinkTools.LinkSetData(d, "Type", 0); // Object
            LinkTools.LinkSetData(d, "rel pos", offset);
            LinkTools.LinkSetData(d, "Flags", 1); // No Auto-Delete

            // TODO: if we want a fade to black, we apparently need to start it
            //       before the teleport??? or maybe that is just a not-doing-it-
            //       via-script thing.
            Object.Teleport(self, vector(), vector(), pointer);
            Link.Create("PhysAttach", self, target);

            PostMessage(target, "PossessEnableFix", 1);
            PostMessage(self, "PossessReanchor");
        } else {
            if (! Object.HasMetaProperty(anchor, "M-PossessMouselookFix")) {
                Object.AddMetaProperty(anchor, "M-PossessMouselookFix");
            }
            Object.Teleport(anchor, toPos, toFacing);

            // TODO: if we want a fade to black, we apparently need to start it
            //       before the teleport??? or maybe that is just a not-doing-it-
            //       via-script thing.
            Object.Teleport(self, vector(), vector(), anchor);
            Link.Create("PhysAttach", self, anchor);
            PostMessage(anchor, "PossessEnableFix", 1);
        }
        // And keep track of what we are possessing.
        local link = Link.Create("ScriptParams", self, target);
        LinkTools.LinkSetData(link, "", "Possessed");
        // NOTE: We prevent frobbing most objects while possessed by generously
        //       adding this metaproperty to all physical objects. This won't
        //       work for any objects in e.g. the fnord or SFX trees have been
        //       made frobbable; and it won't work for concrete objects with
        //       a direct FrobInfo property on them making them frobbable.
        //       Those must be avoided when using this script.
        // NOTE: The PossessFrobs are both fnords *and* have a direct FrobInfo
        //       property, so they will be unaffected, as they need to be.
        // NOTE: If we only need right-frob, then we can change PossessFrobRight
        //       to be a junk item, because *nothing* can be frobbed while
        //       holding a junk item.
//        Object.AddMetaPropertyToMany("M-NoFrobWhilePossessed", "@physical");

        // TEMP: we don't have a way to manually detach yet, so automate it.
        SetOneShotTimer("TempDetach", 15.0);
    }

    function OldEndPossession(position, facing) {
        if (! IsPossessing()) {
            print("ERROR! Tried to unpossess when not possessing. Fix this bug!");
            return false;
        }
        EndTargeting(false);
        // NOTE: we must clear IsPossessing *before* inventory restoration, so
        //       that we won't react to the Container messages.
        SetData("IsPossessing", false);
        local target = GetPossessedObject();
        local anchor = Possess.GetAnchor();
        local pointer = Possess.GetAnchorPointer();
        local wasAt = Possess.GetWasAt();
        local inv = Possess.GetInventory();
        local frobL = Possess.GetFrobLeft();
        local frobR = Possess.GetFrobRight();
        // Stop the mouselook fix (no matter who is running it).
        SendMessage(anchor, "PossessEnableFix", 0);
        SendMessage(target, "PossessEnableFix", 0);
        // Disconnect from the anchor (or target).
        local link = Link.GetOne("PhysAttach", self, anchor);
        if (link==0) {
            link = Link.GetOne("PhysAttach", self, target);
            if (link==0) {
                print("ERROR! Unpossessed when not PhysAttached. Fix this bug!");
            }
        }
        Link.Destroy(link);
        // Disconnect the anchor pointer (if attached).
        link = Link.GetOne("DetailAttachement", pointer, target);
        if (link!=0) {
            Link.Destroy(link);
        }
        // Disconnect from the possessed target.
        link = GetPossessedLink();
        if (link==0) {
            print("ERROR! Unpossessed with no ScriptParams('Possessed') link. Fix this bug!");
        }
        Link.Destroy(link);
        // Restore the player's collision response.
        local collisionType = GetData("PlayerCollisionType");
        SetProperty("CollisionType", collisionType);
        // Restore player position.
        Object.Teleport(self, position, facing);
        // Restore inventory, setting the global flag to prevent loot sounds.
        EnableLootSounds(false);
        Container.Remove(frobL, self);
        Container.Remove(frobR, self);
        // TODO: will need to suppress loot sounds... maybe by making a custom
        //       squirrel LootSounds to use in preference to gen's?
        Container.MoveAllContents(inv, self, CTF_NONE);
        EnableLootSounds(true);
        // Park the anchor back at the origin ready for next time.
        Object.Teleport(anchor, vector(), vector());
        // Restore frobs.
        Object.RemoveMetaPropertyFromMany("M-NoFrobWhilePossessed", "@physical");
    }

    function OnPossessReanchor() {
        if (IsPossessing()) {
            local anchor = Possess.GetAnchor();
            local pointer = Possess.GetAnchorPointer();
            local target = GetPossessedObject();
            local link = Link.GetOne("PhysAttach", self, target);
            if (link==0) {
                // Should exist! but never mind.
                print("Error: player has no PhysAttach"); // TEMP
                return;
            }
            local targetPos = Object.Position(target);
            local pointerPos = Object.Position(pointer);
            local offset = pointerPos-targetPos;
            LinkTools.LinkSetData(link, "Offset", offset);
            PostMessage(self, "PossessReanchor");
        }
    }

    function IsTargetValid() {
        return GetData("IsTargetValid");
    }

    function GetTargetPosition() {
        return GetData("TargetPosition");
    }

    function GetTargetFacing() {
        return GetData("TargetFacing");
    }

    function SetTarget(position, facing, valid) {
        SetData("IsTargetValid", valid);
        SetData("TargetPosition", position);
        SetData("TargetFacing", facing);
    }

    function BeginTargeting() {
        if (IsTargeting()) return false;
        SetData("IsTargeting", true);
        SetTarget(vector(), vector(), false);
        EnableTargetingTimer(true);
    }

    function EndTargeting(commit) {
        if (! IsTargeting()) return false;
        SetData("IsTargeting", false);
        EnableTargetingTimer(false);
        local ghost = Possess.GetGhost();
        Property.SetSimple(ghost, "RenderType", 1); // Not Rendered
        if (commit
        && IsTargetValid()) {
            EndPossession(GetTargetPosition(), GetTargetFacing());
            return true;
        }
        return false;
    }

    function DoTargeting() {
        // NOTE: Camera coordinates for CameraToWorld are x-forward, z-up.
        const max_distance = 20.0;
        local from = Camera.GetPosition();
        local to = Camera.CameraToWorld(vector(max_distance,0.0,0.0));
        local dir = (to-from); dir.Normalize();

        local hit_object = object();
        local hit_position = vector();
        local hit = Engine.ObjRaycast(from, to, hit_position, hit_object,
            0,          // Always find the nearest object, not just line-of-sight.
            0x2,        // Include meshes but ignore invisible objects.
            "Player",               // Ignore the player.
            Possess.GetGhost());    // Ignore the ghost.
        // TODO: if the hit is GetPossessedObject(), we need to disregard that!
        // TODO: if the hit has no physics, then what? redo the raycast ignoring
        //       it too?? particles? decals? this is maybe awkward...
        // TODO: maybe fire a high speed projectile (not a clone, keep it around)
        //       so we get a poor man's physics raycast? see Physics.LaunchProjectile
        local position = vector();
        local facing = vector();
        local valid = false;
        if (hit) {
            // Probe the destination to see if it is a valid position for the
            // player's bits.
            // TODO: we really need a normal so we can decide whether to treat
            //       the hit position as the foot position, or whether to walk
            //       back along it by PLAYER_RADIUS and treat it as a potential
            //       body position (then phys/raycast down to find the floor).
            local headOffset = GetData("PlayerHeadOffset");
            local bodyOffset = GetData("PlayerBodyOffset");
            local footOffset = GetData("PlayerFootOffset");
            local headProbe = Possess.GetHeadProbe();
            local bodyProbe = Possess.GetBodyProbe();
            local footProbe = Possess.GetFootProbe();
            Object.Teleport(headProbe, hit_position+headOffset-footOffset, vector());
            Object.Teleport(bodyProbe, hit_position+bodyOffset-footOffset, vector());
            Object.Teleport(footProbe, hit_position, vector());
            local headValid = Physics.ValidPos(headProbe);
            local bodyValid = Physics.ValidPos(bodyProbe);
            local footValid = Physics.ValidPos(footProbe);

            local msg = "head:"+headValid+" body:"+bodyValid+" foot:"+footValid;
            DarkUI.TextMessage(msg, 0, 100);

            valid = (headValid && bodyValid && footValid);
            if (valid) {
                position = hit_position-footOffset;
                facing.z = atan2(dir.y,dir.x)*57.29578; // 180/pi
            }
        }

        local ghost = Possess.GetGhost();
        if (valid) {
            SetTarget(position, facing, true);
            // make ghost face the other way
            // TODO: delete this, its just convenient for the playbox ghost
            local invAngle = facing.z+180.0;
            if (invAngle>=360.0) invAngle -= 360.0;
            Object.Teleport(ghost, position, vector(0.0,0.0,invAngle));
            Property.SetSimple(ghost, "RenderType", 2); // Unlit
        } else {
            SetTarget(position, facing, false);
            Property.SetSimple(ghost, "RenderType", 1); // Not Rendered
        }

        // TODO: delete:
        // local msg;
        // if (hit==0) {
        //     msg = "no hit";
        // } else {
        //     // 1 for terrain, 2 for an object, 3 for mesh object. For return
        //     // types 2 and 3, the hit object will be returned in 'hit_object'.
        //     msg = "hit type "+hit+", objid "+hit_object+" name:"+Object.GetName(hit_object.tointeger());
        // }
        // DarkUI.TextMessage(msg, 0, 100);
    }

    function EnableTargetingTimer(enable) {
        local timer = GetData("TargetingTimer");
        if (enable && timer==0) {
            // TODO: low frequency targeting means the target visuals are
            //       juddery... but maybe that will go away when we change to
            //       use particle system visuals?
            timer = SetOneShotTimer("DoTargeting", 0.030);
            SetData("TargetingTimer", timer);
        }
        if (!enable && timer!=0) {
            KillTimer(timer);
            SetData("TargetingTimer", 0);
        }
    }

    function OnTimer() {
        if (message().name=="TempDetach") {
            local wasAt = Possess.GetWasAt();
            EndPossession(Object.Position(wasAt), Object.Facing(wasAt));
            return;
        }
        if (message().name=="DoTargeting") {
            SetData("TargetingTimer", 0);
            EnableTargetingTimer(true);
            DoTargeting();
            return;
        }
    }
}

class OldPossessMouselookFix extends SqRootScript {
    function IsDoor(obj) {
        return (Property.Possessed(obj,"RotDoor")
            || Property.Possessed(obj,"TransDoor"));
    }

    function OnBeginScript() {
        SetData("Active", 0);
        SetData("Override", 0);
    }

    function OnPossessEnableFix() {
        local enable = (message().data==1);
        SetData("Active", (enable? 1 : 0));
        ApplyFix();
        if (enable) {
            ApplyDoorHack();
        }
    }

    function EnableOverride(override) {
        SetData("Override", (override? 1 : 0));
        ApplyFix();
    }

    function OnDoorOpening() { EnableOverride(true); }
    function OnDoorClosing() { EnableOverride(true); }
    function OnDoorOpen()    { EnableOverride(false); }
    function OnDoorClose()   { EnableOverride(false); }
    function OnDoorHalt()    { EnableOverride(false); }

    function ApplyFix() {
        // HACK: If the anchor the player is PhysAttached to is stationary,
        //       then the player can only turn the camera horizontally, not
        //       vertically. It makes no sense, but that is what happens.
        //       To work around this, we need to control the anchor's velocity
        //       with a nonzero value; but controlling velocity disables
        //       location controls. So we make sure the anchor has no gravity,
        //       so it won't fall; we control its velocity with a small value
        //       that is nonzero so the camera works, but because the value is
        //       less than 1, it doesnt end up actually moving? Also weird,
        //       but it works for us.
        local isActive = (GetData("Active")==1);
        // When the override is on, we always disable the fix.
        local isOverride = (GetData("Override")==1);
        if (isOverride) {
            isActive = false;
        }
        if (isActive) {
            SetData("Active", 1);
            Physics.SetGravity(self, 0.0);
            // NOTE: Physics.ControlVelocity() is Thief 2 only. We do this instead:
            local velocity = vector(0,0,0.1);
            local controls = Property.Get(self, "PhysControl", "Controls Active");
            Property.Set(self, "PhysControl", "Velocity", velocity);
            Property.Set(self, "PhysControl", "Controls Active", (controls&~8)|2); // +Velocity, -Location
        } else {
            SetData("Active", 0);
            Physics.SetGravity(self, 1.0); // TODO: should restore, not set, right?
            // NOTE: Physics.StopControlVelocity() is Thief 2 only. We do this instead:
            local controls = Property.Get(self, "PhysControl", "Controls Active");
            Property.Set(self, "PhysControl", "Velocity", vector(0,0,0));
            Property.Set(self, "PhysControl", "Controls Active", (controls&~2)|8); // -Velocity, +Location
            Physics.ControlCurrentPosition(self);
        }
    }

    function ApplyDoorHack() {
        if (IsDoor(self)) {
            // HACK: While the bare fix works okay on say, a statue, when
            //       applied to a door, the controlled velocity *does* cause
            //       the door to start drifting. No idea why the a difference!
            //       But once the door has begun moving and stopped moving,
            //       the velocity does not remain. Why? Good question.
            //       So to work around that, we re-open or re-close the door
            //       here just to kick things off. Note that we assume that
            //       the door was halted while *opening*, since that is more
            //       usual in Thief. If that assumption turns out to be a
            //       problem, then we can fix it later.
            // Silence the door while we do the hack.
            local tags = GetProperty("Class Tags", "1: Tags");
            SetProperty("Class Tags", "1: Tags", "");
            local state = Door.GetDoorState(self);
            if (state==eDoorStatus.kDoorClosed
            || state== eDoorStatus.kDoorClosing) {
                Door.OpenDoor(self);
                Door.CloseDoor(self);
            } else if (state== eDoorStatus.kDoorOpen
            || state==eDoorStatus.kDoorOpening
            || state==eDoorStatus.kDoorHalt) {
                Door.CloseDoor(self);
                Door.OpenDoor(self);
            }
            SetProperty("Class Tags", "1: Tags", tags);
        }
    }

}

// TODO: there is a whole bunch of fiddly state management needed if we are going
//       to have begin/end frobs -- which i would like in order to "aim" at a
//       position to emerge at... at least thats the idea right now. but if
//       frobs are underway, clearing weapon/item cancels then without a cancel
//       message (unless...? is that when message().Abort is true??)

class PossessFrobLeft extends SqRootScript {
    function OnContained() {
        // Make sure we are selected immediately.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        if (message().event==eContainsEvent.kContainAdd) {
            DarkUI.InvSelect(self);
        }
    }

    function OnFrobWorldBegin() {
        // Player left-clicked while possessed.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobWorldEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobInvBegin() {
        // Player left-clicked while possessed.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        if (message().Abort) {
            SendMessage("Player", "FrobLeftAbort");
        } else {
            SendMessage("Player", "FrobLeftBegin");
        }
    }

    function OnFrobInvEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        SendMessage("Player", "FrobLeftEnd");
    }

    function OnFrobToolBegin() {
        // Player left-clicked while possessed and looking at a frobbable.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobToolEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnInvDeSelect() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        // Prevent from being deselected in inventory.
        // NOTE: neither DarkUI.InvSelect(self) nor the inv_select command works
        //       to prevent the weapon from being deselected! So we post a
        //       message to force a reselection next frame.
        PostMessage(self, "ForceReselect");
    }

    function OnForceReselect() {
        DarkUI.InvSelect(self);
    }

/* TODO: restore or delete this idc
    function OnMessage() {
        // TEMP: print all other messages we might need to handle.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }
*/
}

class PossessFrobRight extends SqRootScript {
    function OnContained() {
        // Make sure we are selected immediately.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        if (message().event==eContainsEvent.kContainAdd) {
            DarkUI.InvSelect(self);
        }
    }

    function OnFrobToolBegin() {
        // TODO: see if we have a bug right-frobbing while looking at another
        //       object?
        //       enabling Script+FocusScript for Tool frobs isn't a whole solution,
        //       as it makes the item do the move-to-center behaviour, that we
        //       do *not* want.
        //       fallback workaround if needed: when becoming possessed, we mass-
        //       add a "NoFrobWhenPossessed" metaprop to all non-embodyable objects?
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobToolEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobInvBegin() {
        // NOTE: if we detach while the button is held, we get a
        //       FrobInvBegin message when the button is released,
        //       instead of a FrobInvEnd!
        // TODO: investigate if the same is true for FrobWorld and PossessFrobLeft
        // TODO: is that when message().Abort is true?
        // TODO: handle that, if detach is forced and not happening
        //       as a result of clicks. e.g., just ignore all frob messages when
        //       player is not possessed.
        print("right inv");
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        if (message().Abort) {
            SendMessage("Player", "FrobRightAbort");
        } else {
            SendMessage("Player", "FrobRightBegin");
        }
    }

    function OnFrobInvEnd() {
        print("right inv");
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        SendMessage("Player", "FrobRightEnd");
    }

    function OnInvDeSelect() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        // Prevent from being deselected in inventory.
        // NOTE: neither DarkUI.InvSelect(self) nor the inv_select command works
        //       to prevent the weapon from being deselected! So we post a
        //       message to force a reselection next frame.
        PostMessage(self, "ForceReselect");
    }

    function OnForceReselect() {
        DarkUI.InvSelect(self);
    }

    function OnInvDeFocus() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        // Prevent from timing out/being cleared in inventory.
        if (true) {
            print("TEMP: prevent timing out/deselection");
            // NOTE: Using DarkUI.InvSelect(self) doesn't work to refresh the
            //       PossessFrobRight; but usinv inv_select *does* work:
            Debug.Command("inv_select "+Object.GetName(self));
        }
    }

/* TODO: restore or delete this idc
    function OnMessage() {
        // TEMP: print all other messages we might need to handle.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }
*/
}

class PossessPhysCastProjectile extends SqRootScript {
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnPhysCollision() {
        local hitObj = 0;
        if (message().collType==ePhysCollisionType.kCollTerrain) {
            // NOTE: if we care about the texture, we can get it here from
            //       message().collObj.
            hitObj = 0;
        } else if (message().collType==ePhysCollisionType.kCollObject) {
            hitObj = message().collObj;
            if (Physics.HasPhysics(hitObj)
            && Physics.IsSphere(hitObj)) {
                // Ignore collisions with sphere objects.
                // TODO: we might want to make this size-based instead, so that
                //       e.g. the raycast will hit a barrel, but not a bottle.
                // BUG: this sometimes gets caught up and stops (and maybe later
                //      continues, like much later if we go over to have a look!)
                //      and it sometimes goes through, though not without hitching
                //      up and maybe being weird and slow...
                // WORKAROUND: for now, just hit sphere objects too.
                //
                //Reply(ePhysMessageResult.kPM_Nothing);
                //return;
            }
        }

        // TODO: clean up
        print("Projectile hit:");
        print("  pos:"+message().collPt);
        print("  normal:"+message().collNormal);
        print("  hit obj:"+hitObj);

        SendMessage("Player", "PhysCastHit",
            message().collPt,       // data
            message().collNormal,   // data2
            hitObj);                // data3
        Reply(ePhysMessageResult.kPM_NonPhys);
    }
}

class DebugMessages extends SqRootScript {
    function OnMessage() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }
}
