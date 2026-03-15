function scaleWindow(hyprlandClient, maxWindowWidth, maxWindowHeight) {
    if (!hyprlandClient || !hyprlandClient.size || hyprlandClient.size.length < 2) {
        return Qt.size(maxWindowWidth, maxWindowHeight);
    }
    const [width, height] = hyprlandClient.size;
    if (width <= 0 || height <= 0) {
        return Qt.size(maxWindowWidth, maxWindowHeight);
    }
    const [xScale, yScale] = [maxWindowWidth / width, maxWindowHeight / height];
    const scale = Math.min(xScale, yScale);
    return Qt.size(width * scale, height * scale)
}

function arrangedClients(hyprlandClients, maxRowWidth, maxWindowWidth, maxWindowHeight) {
    if (!hyprlandClients || !Array.isArray(hyprlandClients)) {
        return [];
    }
    const count = hyprlandClients.length;
    const resultLayout = [];

    var i = 0;
    while (i < count) {
        var row = [];
        var rowWidth = 0;
        var j = i;

        while (j < count) {
            const client = hyprlandClients[j];
            if (!client) {
                j++;
                continue;
            }
            const scaledSize = scaleWindow(client, maxWindowWidth, maxWindowHeight);

            if (rowWidth + scaledSize.width <= maxRowWidth || row.length === 0) {
                row.push(client);
                rowWidth += scaledSize.width;
                j++;
            } else {
                break;
            }
        }

        if (row.length > 0) {
            resultLayout.push(row);
        }
        i = j;
    }

    return resultLayout;
}
