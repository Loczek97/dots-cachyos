pragma Singleton
import QtQuick
import Quickshell.Hyprland

QtObject {
    property var hyprland: Hyprland
    property var clients: {
        console.log("=== HyprlandData clients property evaluation ===");
        console.log("  Hyprland:", Hyprland);
        console.log("  Hyprland.clients:", Hyprland.clients);
        
        // Spróbuj użyć Hyprland.clients bezpośrednio
        if (Hyprland.clients !== undefined && Hyprland.clients !== null) {
            console.log("  Found Hyprland.clients, type:", typeof Hyprland.clients);
            console.log("  Hyprland.clients.length:", Hyprland.clients.length);
            return Hyprland.clients;
        }
        
        console.log("  Hyprland.clients not available, returning empty array");
        return [];
    }
    
    property var activeWorkspace: Hyprland.focusedMonitor?.activeWorkspace
    
    Component.onCompleted: {
        console.log("=== HyprlandData initialized ===");
        console.log("  Hyprland:", Hyprland);
        console.log("  Hyprland.clients:", Hyprland.clients);
        console.log("  clients.length:", clients ? clients.length : "NULL");
        if (clients && clients.length > 0) {
            for (var i = 0; i < Math.min(5, clients.length); i++) {
                console.log("    Client", i, ":", clients[i].title, "workspace:", clients[i].workspace.id);
            }
        }
    }
    
    property var workspaces: {
        if (!Hyprland.workspaces) return [];
        var arr = [];
        var ws = Hyprland.workspaces;
        if (Array.isArray(ws)) {
            return ws;
        }
        // Konwersja QML list do array
        for (var key in ws) {
            if (ws.hasOwnProperty(key) && typeof ws[key] === 'object') {
                arr.push(ws[key]);
            }
        }
        return arr;
    }
    
    function clientForToplevel(toplevel) {
        // Teraz toplevels to są bezpośrednio Hyprland.clients, więc toplevel = client
        return toplevel;
    }
    
    property var windowByAddress: {
        const map = {};
        for (const client of Hyprland.clients) {
            map[client.address] = client;
        }
        return map;
    }
    
    function toplevelsForWorkspace(workspaceId) {
        var result = [];
        var allClients = clients;
        if (!allClients || allClients.length === 0) {
            return result;
        }
        for (var i = 0; i < allClients.length; i++) {
            var client = allClients[i];
            if (client && client.workspace && client.workspace.id === workspaceId) {
                result.push(client);
            }
        }
        console.log("Workspace", workspaceId, "has", result.length, "windows");
        return result;
    }
}
