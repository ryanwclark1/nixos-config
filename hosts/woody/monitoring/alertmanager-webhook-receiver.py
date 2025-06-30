#!/usr/bin/env python3
"""
Alertmanager Webhook Receiver
Handles incoming webhooks from Prometheus Alertmanager
"""

import json
import logging
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('alertmanager-webhook')

# Configuration
LISTEN_HOST = '127.0.0.1'
LISTEN_PORT = 5001
BEARER_TOKENS = {
    '/': 'default-webhook-token',
    '/critical': 'critical-webhook-token',
    '/production': 'prod-webhook-token'
}

class AlertmanagerWebhookHandler(BaseHTTPRequestHandler):
    """Handle incoming webhook requests from Alertmanager"""
    
    def do_POST(self):
        """Process POST requests containing alert data"""
        try:
            # Parse URL path
            parsed_path = urlparse(self.path)
            endpoint = parsed_path.path
            
            # Validate bearer token if configured
            if endpoint in BEARER_TOKENS:
                auth_header = self.headers.get('Authorization', '')
                expected_token = f'Bearer {BEARER_TOKENS[endpoint]}'
                if auth_header != expected_token:
                    logger.warning(f'Invalid bearer token for endpoint {endpoint}')
                    self.send_error(401, 'Unauthorized')
                    return
            
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            
            # Parse JSON payload
            try:
                alert_data = json.loads(body.decode('utf-8'))
            except json.JSONDecodeError as e:
                logger.error(f'Invalid JSON payload: {e}')
                self.send_error(400, 'Invalid JSON')
                return
            
            # Process alerts based on endpoint
            self.process_alerts(endpoint, alert_data)
            
            # Send success response
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {'status': 'success', 'message': 'Alerts processed'}
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
        except Exception as e:
            logger.error(f'Error processing webhook: {e}', exc_info=True)
            self.send_error(500, 'Internal Server Error')
    
    def process_alerts(self, endpoint, data):
        """Process alerts based on endpoint and data"""
        status = data.get('status', 'unknown')
        receiver = data.get('receiver', 'unknown')
        alerts = data.get('alerts', [])
        
        logger.info(f'Received {len(alerts)} alerts on {endpoint} from {receiver} (status: {status})')
        
        for alert in alerts:
            labels = alert.get('labels', {})
            annotations = alert.get('annotations', {})
            
            alert_name = labels.get('alertname', 'Unknown')
            severity = labels.get('severity', 'unknown')
            instance = labels.get('instance', 'unknown')
            component = labels.get('component', 'unknown')
            summary = annotations.get('summary', 'No summary')
            description = annotations.get('description', 'No description')
            
            starts_at = alert.get('startsAt', '')
            ends_at = alert.get('endsAt', '')
            
            # Log alert details
            logger.info(f'Alert: {alert_name} [{severity}] on {instance}')
            logger.info(f'  Component: {component}')
            logger.info(f'  Summary: {summary}')
            logger.info(f'  Description: {description}')
            logger.info(f'  Started: {starts_at}')
            if ends_at and status == 'resolved':
                logger.info(f'  Ended: {ends_at}')
            
            # Route to specific handlers based on endpoint
            if endpoint == '/critical':
                self.handle_critical_alert(alert, status)
            elif endpoint == '/security':
                self.handle_security_alert(alert, status)
            elif endpoint == '/security/urgent':
                self.handle_urgent_security_alert(alert, status)
            elif endpoint == '/database/critical':
                self.handle_database_alert(alert, status)
            elif endpoint == '/production':
                self.handle_production_alert(alert, status)
            else:
                self.handle_default_alert(alert, status)
    
    def handle_critical_alert(self, alert, status):
        """Handle critical alerts - implement paging, escalation, etc."""
        logger.warning(f'CRITICAL ALERT: {alert}')
        # TODO: Implement critical alert handling
        # - Send to PagerDuty
        # - Create incident ticket
        # - Notify on-call engineer
    
    def handle_security_alert(self, alert, status):
        """Handle security alerts - implement SIEM forwarding, etc."""
        logger.warning(f'SECURITY ALERT: {alert}')
        # TODO: Implement security alert handling
        # - Forward to SIEM
        # - Create security incident
        # - Notify security team
    
    def handle_urgent_security_alert(self, alert, status):
        """Handle urgent security alerts like brute force attempts"""
        logger.error(f'URGENT SECURITY ALERT: {alert}')
        # TODO: Implement urgent security handling
        # - Immediate notification
        # - Automated response actions
        # - Security team escalation
    
    def handle_database_alert(self, alert, status):
        """Handle database-specific alerts"""
        logger.warning(f'DATABASE ALERT: {alert}')
        # TODO: Implement database alert handling
        # - Notify DBA team
        # - Check for data integrity
        # - Initiate failover if needed
    
    def handle_production_alert(self, alert, status):
        """Handle production environment alerts"""
        logger.warning(f'PRODUCTION ALERT: {alert}')
        # TODO: Implement production alert handling
        # - Create incident
        # - Notify stakeholders
        # - Update status page
    
    def handle_default_alert(self, alert, status):
        """Default alert handler"""
        logger.info(f'DEFAULT HANDLER: {alert}')
        # TODO: Implement default handling
        # - Log to database
        # - Send to notification channel
    
    def log_message(self, format, *args):
        """Override to suppress default HTTP logging"""
        pass

def run_webhook_server():
    """Run the webhook server"""
    server_address = (LISTEN_HOST, LISTEN_PORT)
    httpd = HTTPServer(server_address, AlertmanagerWebhookHandler)
    
    logger.info(f'Starting Alertmanager webhook receiver on {LISTEN_HOST}:{LISTEN_PORT}')
    logger.info(f'Configured endpoints: {list(BEARER_TOKENS.keys())}')
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info('Shutting down webhook receiver')
        httpd.shutdown()

if __name__ == '__main__':
    run_webhook_server()