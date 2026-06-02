resource "yandex_monitoring_dashboard" "main" {
  name        = "${local.project}-dashboard"
  title       = "UniJobs Observability"
  description = "Dashboard entry point for UniJobs infrastructure metrics."
  labels      = local.labels

  widgets {
    title {
      text = "API Gateway"
      size = "TITLE_SIZE_M"
    }

    position {
      x = 0
      y = 0
      w = 12
      h = 1
    }
  }

  widgets {
    chart {
      chart_id       = "gateway-requests-per-second"
      title          = "Gateway requests per second"
      display_legend = true

      queries {
        target {
          query = "\"api_gateway.requests_count_per_second\"{service=\"serverless-apigateway\", gateway=\"${yandex_api_gateway.app.name}\", path=\"total\", release=\"stable\", code=\"*\"}"
        }
      }
    }

    position {
      x = 0
      y = 1
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "gateway-errors-per-second"
      title          = "Gateway errors per second"
      display_legend = true

      queries {
        target {
          query = "\"api_gateway.errors_count_per_second\"{service=\"serverless-apigateway\", gateway=\"${yandex_api_gateway.app.name}\", path=\"total\", release=\"stable\", code=\"*\"}"
        }
      }
    }

    position {
      x = 6
      y = 1
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "gateway-api-latency-p95"
      title          = "Gateway /api p95 latency, ms"
      display_legend = true

      queries {
        target {
          query = "histogram_percentile(95, \"api_gateway.requests_latency_milliseconds\"{service=\"serverless-apigateway\", gateway=\"${yandex_api_gateway.app.name}\", path=\"/api/{proxy+}\", release=\"stable\", le=\"*\"})"
        }
      }
    }

    position {
      x = 0
      y = 7
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "gateway-api-requests-per-second"
      title          = "Gateway /api requests per second"
      display_legend = true

      queries {
        target {
          query = "\"api_gateway.requests_count_per_second\"{service=\"serverless-apigateway\", gateway=\"${yandex_api_gateway.app.name}\", path=\"/api/{proxy+}\", release=\"stable\", code=\"*\"}"
        }
      }
    }

    position {
      x = 6
      y = 7
      w = 6
      h = 6
    }
  }

  widgets {
    title {
      text = "Serverless Backend"
      size = "TITLE_SIZE_M"
    }

    position {
      x = 0
      y = 13
      w = 12
      h = 1
    }
  }

  widgets {
    chart {
      chart_id       = "backend-started-per-second"
      title          = "Backend starts per second"
      display_legend = true

      queries {
        target {
          query = "\"serverless.containers.started_per_second\"{service=\"serverless-containers\", container=\"${yandex_serverless_container.backend.name}\"}"
        }
      }
    }

    position {
      x = 0
      y = 14
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "backend-errors-per-second"
      title          = "Backend errors per second"
      display_legend = true

      queries {
        target {
          query = "\"serverless.containers.errors_per_second\"{service=\"serverless-containers\", container=\"${yandex_serverless_container.backend.name}\"}"
        }
      }
    }

    position {
      x = 6
      y = 14
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "backend-execution-time-p95"
      title          = "Backend p95 execution time, ms"
      display_legend = true

      queries {
        target {
          query = "histogram_percentile(95, \"serverless.containers.execution_time_milliseconds\"{service=\"serverless-containers\", container=\"${yandex_serverless_container.backend.name}\", le=\"*\"})"
        }
      }
    }

    position {
      x = 0
      y = 20
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "backend-memory-p95"
      title          = "Backend p95 memory, bytes"
      display_legend = true

      queries {
        target {
          query = "histogram_percentile(95, \"serverless.containers.used_memory_bytes\"{service=\"serverless-containers\", container=\"${yandex_serverless_container.backend.name}\", le=\"*\"})"
        }
      }
    }

    position {
      x = 6
      y = 20
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "backend-initializations-per-second"
      title          = "Backend cold starts per second"
      display_legend = true

      queries {
        target {
          query = "\"serverless.containers.initializations_per_second\"{service=\"serverless-containers\", container=\"${yandex_serverless_container.backend.name}\"}"
        }
      }
    }

    position {
      x = 0
      y = 26
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "backend-inflight"
      title          = "Backend inflight requests"
      display_legend = true

      queries {
        target {
          query = "\"serverless.containers.inflight\"{service=\"serverless-containers\", container=\"${yandex_serverless_container.backend.name}\"}"
        }
      }
    }

    position {
      x = 6
      y = 26
      w = 6
      h = 6
    }
  }

  widgets {
    title {
      text = "Serverless YDB"
      size = "TITLE_SIZE_M"
    }

    position {
      x = 0
      y = 32
      w = 12
      h = 1
    }
  }

  widgets {
    chart {
      chart_id       = "ydb-request-units"
      title          = "YDB request units consumed"
      display_legend = true

      queries {
        target {
          query = "\"resources.request_units.consumed\"{service=\"ydb\", database_serverless=\"${yandex_ydb_database_serverless.unijobs.name}\", category=\"*\"}"
        }
      }
    }

    position {
      x = 0
      y = 33
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "ydb-requests-per-second"
      title          = "YDB completed requests per second"
      display_legend = true

      queries {
        target {
          query = "\"api.request_completed_per_second\"{service=\"ydb\", database_serverless=\"${yandex_ydb_database_serverless.unijobs.name}\", status=\"*\"}"
        }
      }
    }

    position {
      x = 6
      y = 33
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "ydb-api-latency-p95"
      title          = "YDB API p95 latency, ms"
      display_legend = true

      queries {
        target {
          query = "histogram_percentile(95, \"api.request_latency_milliseconds\"{service=\"ydb\", database_serverless=\"${yandex_ydb_database_serverless.unijobs.name}\", le=\"*\"})"
        }
      }
    }

    position {
      x = 0
      y = 39
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "ydb-storage-used"
      title          = "YDB storage used, bytes"
      display_legend = true

      queries {
        target {
          query = "\"resources.storage.used_bytes\"{service=\"ydb\", database_serverless=\"${yandex_ydb_database_serverless.unijobs.name}\"}"
        }
      }
    }

    position {
      x = 6
      y = 39
      w = 6
      h = 6
    }
  }

  widgets {
    title {
      text = "Object Storage"
      size = "TITLE_SIZE_M"
    }

    position {
      x = 0
      y = 45
      w = 12
      h = 1
    }
  }

  widgets {
    chart {
      chart_id       = "ui-bucket-space-usage"
      title          = "UI bucket space usage, bytes"
      display_legend = true

      queries {
        target {
          query = "\"space_usage\"{service=\"storage\", resource_id=\"${yandex_storage_bucket.ui.bucket}\", resource_type=\"bucket\"}"
        }
      }
    }

    position {
      x = 0
      y = 46
      w = 6
      h = 6
    }
  }

  widgets {
    chart {
      chart_id       = "ui-bucket-object-count"
      title          = "UI bucket object count"
      display_legend = true

      queries {
        target {
          query = "\"objects_count\"{service=\"storage\", resource_id=\"${yandex_storage_bucket.ui.bucket}\", resource_type=\"bucket\", object_type=\"*\"}"
        }
      }
    }

    position {
      x = 6
      y = 46
      w = 6
      h = 6
    }
  }

  widgets {
    text {
      text = "Logs: API Gateway and Serverless Container write to Cloud Logging group ${yandex_logging_group.main.name}. Traces are intentionally not configured."
    }

    position {
      x = 0
      y = 52
      w = 12
      h = 3
    }
  }
}
