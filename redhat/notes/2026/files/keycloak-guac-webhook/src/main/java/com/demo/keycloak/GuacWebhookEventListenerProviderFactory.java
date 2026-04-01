package com.demo.keycloak;

import org.keycloak.Config;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

/**
 * Factory for GuacWebhookEventListenerProvider.
 *
 * Provider ID: "guac-webhook"
 * Register in Keycloak realm: eventsListeners=["jboss-logging","guac-webhook"]
 *
 * Configuration:
 *   KC_WEBHOOK_URL env var → base URL of guac-ldap-sync service
 *   Default: http://guac-ldap-sync:5000
 */
public class GuacWebhookEventListenerProviderFactory implements EventListenerProviderFactory {

    public static final String PROVIDER_ID = "guac-webhook";

    private String webhookBase;

    @Override
    public EventListenerProvider create(KeycloakSession session) {
        return new GuacWebhookEventListenerProvider(webhookBase);
    }

    @Override
    public void init(Config.Scope config) {
        String envUrl = System.getenv("KC_WEBHOOK_URL");
        webhookBase = (envUrl != null && !envUrl.isEmpty())
                ? envUrl
                : "http://guac-ldap-sync:5000";
        System.out.println("[guac-webhook] Initialized. Webhook base URL: " + webhookBase);
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        // Nothing needed
    }

    @Override
    public void close() {
        // Nothing to clean up
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
