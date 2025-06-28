{
  pkgs,
  config,
  ...
}:
{
  services.loki = {
    enable = true;
    user = "loki";
    group = "loki";
    configuration = {
      server = {
        http_listen_port = 3100;
        http_listen_address = "0.0.0.0";
      };
      auth_enabled = false;

      # Use TSDB for better performance (recommended over boltdb-shipper)
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      schema_config = {
        configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v12";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      limits_config = {
        retention_period = "30d";
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        allow_structured_metadata = false;
        
        # Increase ingestion limits to handle high log volume
        ingestion_rate_mb = 16;  # 16 MB/s (default is 4)
        ingestion_burst_size_mb = 32;  # 32 MB burst (default is 6)
        
        # Per-stream limits
        per_stream_rate_limit = "8MB";  # 8 MB/s per stream
        per_stream_rate_limit_burst = "16MB";  # 16 MB burst per stream
        
        # Other limits to prevent resource exhaustion
        max_entries_limit_per_query = 10000;
        max_streams_per_user = 10000;
        max_global_streams_per_user = 10000;
        max_query_length = "0h";  # Unlimited query length
        max_query_parallelism = 32;
      };

      # Ingester configuration
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
      };

      # Compactor configuration
      compactor = {
        working_directory = "/var/lib/loki";
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };

  # Open firewall for Loki
  networking.firewall.allowedTCPPorts = [ 3100 ];
}
