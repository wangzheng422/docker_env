package com.demo.keycloak;

import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;

import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Map;

/**
 * Keycloak EventListener SPI - Guacamole Webhook.
 *
 * On LOGIN event: HTTP POST to {webhookBase}/sync/{username}
 * The guac-ldap-sync service receives this, queries OpenLDAP,
 * and provisions Guacamole connections for the user.
 *
 * Configured via KC_WEBHOOK_URL env var (default: http://guac-ldap-sync:5000)
 */
public class GuacWebhookEventListenerProvider implements EventListenerProvider {

    private static final String LOG_PREFIX = "[guac-webhook]";
    private final String webhookBase;

    public GuacWebhookEventListenerProvider(String webhookBase) {
        this.webhookBase = webhookBase;
    }

    @Override
    public void onEvent(Event event) {
        if (event.getType() != EventType.LOGIN) {
            return;
        }

        Map<String, String> details = event.getDetails();
        if (details == null) {
            return;
        }

        String username = details.get("username");
        if (username == null || username.isEmpty()) {
            System.out.println(LOG_PREFIX + " LOGIN event has no username, skipping");
            return;
        }

        System.out.println(LOG_PREFIX + " LOGIN detected: " + username
                + " (realm=" + event.getRealmId() + ")");
        callWebhook(username);
    }

    @Override
    public void onEvent(AdminEvent event, boolean includeRepresentation) {
        // No action needed for admin events
    }

    @Override
    public void close() {
        // Nothing to clean up
    }

    private void callWebhook(String username) {
        String targetUrl = webhookBase + "/sync/" + username;
        try {
            URL url = new URL(targetUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(10000);
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Content-Length", "0");
            try (OutputStream os = conn.getOutputStream()) {
                os.write(new byte[0]);
            }
            int responseCode = conn.getResponseCode();
            System.out.println(LOG_PREFIX + " Synced " + username
                    + " -> HTTP " + responseCode + " (" + targetUrl + ")");
            conn.disconnect();
        } catch (IOException e) {
            System.err.println(LOG_PREFIX + " ERROR syncing " + username
                    + ": " + e.getMessage());
        }
    }
}
