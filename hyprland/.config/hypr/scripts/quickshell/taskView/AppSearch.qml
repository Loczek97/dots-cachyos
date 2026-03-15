pragma Singleton
import QtQuick
import "DesktopIconCache.js" as DesktopIconCache

QtObject {
    readonly property var desktopIcons: DesktopIconCache.desktopIcons || ({})
    readonly property var preferredIcons: ({
        "steam": "steam",
        "steamwebhelper": "steam",
        "code": "file:///usr/share/pixmaps/visual-studio-code.png",
        "discord": "file:///opt/discord/discord.png",
        "discordptb": "file:///opt/discord/discord.png",
        "vscode": "file:///usr/share/pixmaps/visual-studio-code.png",
        "visual-studio-code": "file:///usr/share/pixmaps/visual-studio-code.png"
    })

    function normalizeToken(value) {
        return (value || "")
            .toLowerCase()
            .replace(/\.desktop$/g, "")
            .replace(/^"|"$/g, "")
            .replace(/[%].*$/g, "")
            .replace(/[/\\]/g, "-")
            .replace(/[\s_]+/g, "-")
            .replace(/[^a-z0-9.+-]+/g, "-")
            .replace(/-+/g, "-")
            .replace(/^-|-$/g, "");
    }

    function expandAliases(value) {
        const normalized = normalizeToken(value);
        if (!normalized) return [];

        const parts = normalized.split(".");
        const aliases = [normalized];

        if (normalized.endsWith("-url-handler")) {
            aliases.push(normalized.slice(0, -"-url-handler".length));
        }

        if (normalized.startsWith("jetbrains-")) {
            aliases.push(normalized.slice("jetbrains-".length));
        }

        if (parts.length > 1) {
            aliases.push(parts[parts.length - 1]);
            aliases.push(parts.join("-"));
            aliases.push(parts.join(""));
        }

        for (const part of normalized.split("-")) {
            if (part.length > 2) aliases.push(part);
        }

        return [...new Set(aliases.filter(Boolean))];
    }

    function addAliases(target, value, resolvedIcon) {
        const aliases = expandAliases(value);
        for (const alias of aliases) {
            if (!target[alias]) {
                target[alias] = resolvedIcon;
            }
        }
    }

    function resolveDesktopIcon(iconPath, iconName) {
        if ((iconPath || "").startsWith("/")) {
            return "file://" + iconPath;
        }

        const normalizedIcon = normalizeToken(iconName);
        if (normalizedIcon) {
            return normalizedIcon;
        }

        return "";
    }

    function guessIcon(className) {
        if (!className) return "application-x-executable";

        const aliases = expandAliases(className);
        for (const alias of aliases) {
            if (preferredIcons[alias]) {
                if (className === "code" || className === "discord") {
                    console.log(`[AppSearch] class=${className} alias=${alias} preferred=${preferredIcons[alias]}`);
                }
                return preferredIcons[alias];
            }
            if (desktopIcons[alias]) {
                if (className === "code" || className === "discord") {
                    console.log(`[AppSearch] class=${className} alias=${alias} cache=${desktopIcons[alias]}`);
                }
                return desktopIcons[alias];
            }
        }

        if (className === "code" || className === "discord") {
            console.log(`[AppSearch] class=${className} fallback=${aliases.length > 0 ? aliases[0] : "application-x-executable"}`);
        }

        return aliases.length > 0 ? aliases[0] : "application-x-executable";
    }
}
