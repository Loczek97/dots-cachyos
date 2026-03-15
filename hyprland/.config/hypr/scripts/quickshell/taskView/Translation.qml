pragma Singleton
import QtQuick

QtObject {
    function tr(text) {
        // Proste tłumaczenia PL
        const translations = {
            "Desktop %1": "Pulpit %1",
            "New desktop": "Nowy pulpit",
            "Show this window on all desktops": "Pokaż to okno na wszystkich pulpitach",
            "Close": "Zamknij"
        };
        
        return translations[text] || text;
    }
}
