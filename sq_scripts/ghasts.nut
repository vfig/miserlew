log <- function(message) {
    //if (true || Engine.ConfigIsDefined("log_routine"))
    print("Rt. "+message);
}

class WineChoreography extends SqRootScript
{
    function HasActiveRoutine() {
        return (GetRoutine()!=0);
    }

    function GetRoutine() {
        local link = Link.GetOne("AIDefendObj", self);
        if (link!=0)
            return LinkDest(link);
        return 0;
    }

    function ClearRoutine() {
        local link = Link.GetOne("AIDefendObj", self);
        if (link!=0) {
            local pt = LinkDest(link);
            log("Disconnecting from "+desc(pt));
            Link.Destroy(link);
            foreach (link in Link.GetAll("AIWatchObj", self, pt))
                Link.Destroy(link);
        }
    }

    function SetRoutine(pt) {
        if (typeof(pt)=="string") {
            local o = Object.Named(pt);
            if (o==0) {
                log("No such object: "+pt);
                return false;
            }
            pt = o;
        }
        log("Creating routine to "+desc(pt));
        // If we already have a routine, disconnect from it.
        ClearRoutine();
        // I want the AI to go to our routine point as a priority over almost
        // everything. AIDefendObj outranks patrolling (good) and investigating
        // (good enough), but does not outrank attacking an enemy. Works for me!
        local link = Link.Create("AIDefendObj", self, pt);
        LinkTools.LinkSetData(link, "Return speed", 3); // Normal
        LinkTools.LinkSetData(link, "Range 1: Radius", 3); // NOTE: Same radius and height
        LinkTools.LinkSetData(link, "         Height", 6); //       as patrol targets.
        LinkTools.LinkSetData(link, "         Minimum alertness", 0); // None
        LinkTools.LinkSetData(link, "         Maximum alertness", 3); // High
        // Ideally the AI will do something once they get to the patrol point.
        // Set up watch link defaults on it to make that happen.
        if (Property.Possessed(pt, "AI_WtchPnt"))
            Link.Create("AIWatchObj", self, pt);
        return true;
    }

/*
    // TODO: maybe old:

    function SummonWine() {
        return Object.Create("CarriedWine");
    }

    function CarryWine(wine) {
        DetachWine(wine);
        Container.Add(wine, self, eDarkContainType.kContainTypeAlt);
    }

    function AttachWine(wine, elev, marker) {
        Container.Remove(wine);
        DetachWine(wine)
        Object.Teleport(wine, vector(), vector(), marker);
        local offset = Object.Position(marker)-Object.Position(elev);
        local link = Link.Create("PhysAttach", wine, elev);
        LinkTools.LinkSetData(link, "Offset", offset);
    }

    function DetachWine(wine) {
        local link = Link.GetOne("PhysAttach", wine);
        if (link!=0)
            Link.Destroy(link);
    }
*/
}

/* PLAN:

    What are we doing?
        - Attacking/Investigating [= has AIAttack or AIInvest link]
        - Going to interact with something [= has Owns link; and AIWatchObj link to it for actions when reaching there]
        - Interrupted, but need to go to something [= has Owns link only]
        - Idle

    Is that all we need? If so, the trigger for this can be an AIWatchObj on ourself.
    Just check every couple seconds if

-------------------------------------------------------------------------------

Idle: Patrol on the normal path.



*/
class Clyde extends WineChoreography
{
    /* Signal received, time to do a routine */

    function OnSignalAI() {
        log(message().message+":"+message().signal);
        if (message().signal=="gong_ring") {
            // RtBeginFetchWine();
            // TODO - do we handle this here or with Signal Response? does it matter?
        }
    }

    /* Routine: Fetch wine (a bottle if we can, otherwise cask) */

    function OnFetchWine() {
        log(message().message);
        if (HasActiveRoutine()) {
            log(message().message+": already in routine, aborting.");
            return false;
        }
        local bottlePt = Object.Named("ClydeBottlePt");
        if (bottlePt!=0) {
            SetRoutine(bottlePt);
            return;
        }
        local caskPt = Object.Named("ClydeCaskPt");
        if (caskPt!=0) {
            SetRoutine(caskPt);
            return;
        }
        log("ERROR: neither ClydeBottlePt nor ClydeCaskPt exist!");
    }

    function OnAnyWineBottles_() {
        log(message().message);
        local link = Link.GetOne("Population", "BottleRoom");
        if (link!=0) {
            // There are bottles! Reserve one so we can get it.
            log("There are wine bottles.");
            local bottle = LinkDest(link);
            if (! Object.HasMetaProperty(bottle, "M-ReservedForAI"))
                Object.AddMetaProperty(bottle, "M-ReservedForAI");
            Reply(true);
        } else {
            // No more bottles left, so never look here again.
            log("No more wine bottles.");
            local bottlePt = Object.Named("ClydeBottlePt");
            if (bottlePt!=0) {
                Object.Destroy(bottlePt);
            }
            // Fall back to fetching wine again from scratch.
            PostMessage(self, "FetchWine");
            Reply(false);
        }
    }

    // TODO: should reserve a wine bottle so the player cant interrupt at this
    //       stage.

    function OnGetWineBottle() {
        log(message().message);
        local link = Link.GetOne("Population", "BottleRoom");
        if (link!=0) {
            local bottle = LinkDest(link);
            // We actually want it in the hand, but kContainTypeHand is nonfunctional.
            Container.Add(bottle, self, eDarkContainType.kContainTypeBelt);
            SetRoutine("ClydeElevPt");
        }
    }

    function OnIsElevatorReady_() {
        log(message().message);
        local elev = Object.Named("MainElev");
        local elevBottomPt = Object.Named("ElevBottomPt");
        local downButton = Object.Named("ElevDownButton2");
        if (elev==0 || elevBottomPt==0 || downButton==0) {
            log("Can't find object needed for IsElevatorReady? script!");
            Reply(false);
            return;
        }
        local terrPt = SendMessage(elev, "At?");
        if (terrPt!=elevBottomPt) {
            log("Elevator is at:"+terrPt);
            log("Elevator is not ready. Waiting...");
            // Would prefer to keep the script to simple logic and decision-making,
            // and have the pseudoscripts make the AI do actions, but to do this
            // loop we would need a multi-stage Conversation rather than just
            // an AIWatchObj, and right now I can't be bothered.
            AI.MakeFrobObjWith(self, downButton, 0);
            Reply(false);
            return;
        }
        if (! Object.HasMetaProperty(elev, "M-ElevPaused"))
            Object.AddMetaProperty(elev, "M-ElevPaused");
        Reply(true);
    }

    function OnLoadElevator() {
        log(message().message);
        local elev = Object.Named("MainElev");
        local burden = 0;
        foreach (link in Link.GetAll("Contains", self)) {
            local type = LinkTools.LinkGetData(link, "");
            if (type==eDarkContainType.kContainTypeBelt
            || eDarkContainType.kContainTypeAlt) {
                burden = LinkDest(link);
                Link.Destroy(link);
                break;
            }
        }
        Object.RemoveMetaProperty(elev, "M-ElevPaused");
        ClearRoutine();
        log("TODO: Found burden:"+burden+", need to load elevator with it.");
    }

/*
    function IsIdle() {

    }

    function GetBurden() {
        local link = Link.GetOne("Owns", self);
        if (link!=0) return LinkDest(link);
        return 0;
    }

    function OnStartConversation() {
        local routine = message().data;
        local conv = Object.Named(routine);
        if (conv==0) {
            print("ERROR: No object named "+routine);
            Reply(false);
            return;
        }
        if (! Object.HasProperty(conv, "AI_Converation"))
            print("ERROR: "+desc(routine)+" has no Conversation property.");
            Reply(false);
            return;
        }
        local link = Link.GetOne("AIConversationActor", conv);
        if (link==0) {
            local link = Link.Create("AIConversationActor", conv, self);
            LinkTools.LinkSetData(link, "Actor ID", 1);
        }
        AI.StartConversation(conv);
    }

    function OnCanGetWine_() {
        // TODO: check if we are carrying wine?
        Reply(true);
    }

    function OnGetWine() {
        // TODO: we need to pick up the wine if we dropped it somewhere!
        local wine = SummonWine();
        CarryWine(wine);
    }

    function OnPutWineOnElev() {
        local elevName = message().data;
        if (elevName==null || elevName=="")
            return;
        local markerName = message().data;
        if (markerName==null || markerName=="")
            return;
        local elev = Object.Named(elevName);
        local marker = Object.Named(markerName);
        if (elev==0 || marker==0) {
            print("ERROR: PutWineOnElev needs elevator name and marker name.");
            Reply(false);
            return;
        }
        // ?!?!?! what is 'wine'? we dont know!!
        AttachWine(wine, elev, marker)
    }
*/
}

/*
class ClydeFetchWine extends SqRootScript
{
    function OnTurnOn() {
        // We will start locked, and unlock once the big transition happens.
        // After that, we only ever want to fire the once, so lock again.
        if (Locked.IsLocked(self))
            return;
        print("Clyde!! Fetch me more wine!!!");
        SetProperty("Locked", true);
        local who = LinkDest(Link.GetOne("Population", self));
        local where = LinkDest(Link.GetOne("Route", self));
        if (who==0 || where==0) {
            print("ERROR: Who? Where?");
            return;
        }
        // Switch up patrol paths.
        Object.RemoveMetaProperty(who, "M-DoesPatrol");
        local link = Link.GetOne("AICurrentPatrol", who);
        if (link!=0)
            Link.Destroy(link);
        Link.Create("AICurrentPatrol", who, where);
        Object.AddMetaProperty(who, "M-DoesPatrol");
    }
}
*/