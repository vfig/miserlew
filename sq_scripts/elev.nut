DEBUG_ELEVATOR <- true;

class ElevatorNotify extends SqRootScript {
    /* Put this on the Vator class so that it can reliably track
    ** which TerrPt it is stopped at (if any). An elevator with
    ** this script will:
    **
    **   - notify each TerrPt it stops at with an ElevArrived message.
    **   - notify each TerrPt it leaves with an ElevDeparted message.
    **   - notify all interested parties of its movements with ElevArrived
    **     and ElevDeparted messages as it moves; the data of the message
    **     is the TerrPt it arrived at/departed from. An interested party
    **     is any object linked from this elevator with a Population link.
    **   - reply to At? messages with the TerrPt it is stopped at, or
    **     with 0 if it is in motion.
    **
    ** Details: uses a singular Route link from this elevator to keep track
    ** of which TerrPt it is at. When getting a Call message, this elevator
    ** needs to use this to figure out if it is actually going to move or not.
    **
    ** All this is necessary because a StdElevator itself doesn't provide this
    ** information; and when stopped at a TerrPt and re-called to it, the
    ** Stopping self-message may not be sent, and the MovingTerrain/Active
    ** property is not reliable (it sometimes remains on).
    */

    function GetAtPoint() {
        local link = Link.GetOne("Route", self);
        if (! link) return 0;
        return LinkDest(link);
    }

    function ClearAtPoint() {
        foreach (link in Link.GetAll("Route", self))
            Link.Destroy(link);
    }

    function SetAtPoint(pt) {
        foreach (link in Link.GetAll("Route", self))
            Link.Destroy(link);
        if (! pt) return;
        Link.Create("Route", self, pt);
    }

    function BroadcastToListeners(message, data) {
        // NOTE: calling SendMessage() will usually disrupt a link query,
        //       so we have to first find all the listeners first, and only
        //       then send them the message. We can't use Link.Broadcast...()
        //       because it doesn't support sending any extra data.
        local listeners = [];
        foreach (link in Link.GetAll("Population", self)) {
            listeners.append(LinkDest(link));
        }
        foreach (obj in listeners) {
            SendMessage(obj, message, data);
        }
    }

    function OnSim() {
        if (message().starting) {
            local link = Link.GetOne("TPathInit", self);
            if (! link) {
                if (DEBUG_ELEVATOR) print("WARNING: elevator "+self+" does not have a TPathInit link.");
                return;
            }
            local atPt = LinkDest(link);
            SetAtPoint(atPt);
            if (DEBUG_ELEVATOR) print("Starting at:"+desc(atPt));
            SendMessage(atPt, "ElevArrived", atPt);
            BroadcastToListeners("ElevArrived", atPt);
        }
    }

    function OnStopping() {
        local link = Link.GetOne("TPathNext", self);
        if (! link) {
            if (DEBUG_ELEVATOR) print("WARNING: elevator "+self+" path simply ends.");
            return;
        }
        local atPt = LinkDest(link);
        if (DEBUG_ELEVATOR) print("Arrived at:"+desc(atPt));
        SetAtPoint(atPt);
        SendMessage(atPt, "ElevArrived", atPt);
        BroadcastToListeners("ElevArrived", atPt);
    }

    function OnCall() {
        local atPt = GetAtPoint();
        // Do nothing if the elevator is between points.
        if (! atPt) return;
        // Ignore if we are called to the point we are already at. The elevator
        // script itself won't see this as important and won't send a Stopping
        // message either, so we won't have a dangling message problem.
        if (atPt==message().from) return;
        if (DEBUG_ELEVATOR) print("Departing from:"+desc(atPt));
        ClearAtPoint();
        SendMessage(atPt, "ElevDeparted", atPt);
        BroadcastToListeners("ElevDeparted", atPt);
    }

    function OnAt_() {
        Reply(GetAtPoint());
    }
}

class ElevPaused extends SqRootScript {
    /* Intended for use on a metaprop. Prevents the elevator from responding
    ** to calls while this script is active. Once the script is removed, it
    ** will process the last call that it received.
    */
    function GetLastCalledPt() {
        foreach (link in Link.GetAll("ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="ElevPausedLink") {
                return LinkDest(link)
            }
        }
        return 0;
    }

    function SetLastCalledPt(terr) {
        local links = [];
        foreach (link in Link.GetAll("ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="ElevPausedLink") {
                links.append(link);
            }
        }
        foreach (link in links) {
            Link.Destroy(link);
        }
        if (terr) {
            local link = Link.Create("ScriptParams", self, terr);
            LinkTools.LinkSetData(link, "", "ElevPausedLink");
            return link;
        }
        return 0;
    }

    function OnBeginScript() {
        SetLastCalledPt(0);
    }

    function OnEndScript() {
        local terr = GetLastCalledPt();
        SetLastCalledPt(0);
        if (terr) {
            PostMessage(terr, "TurnOn");
        }
    }

    function OnCall() {
        SetLastCalledPt(message().from);
        BlockMessage();
        Reply(false);
    }
}
