namespace Api.Helpers;

/// <summary>
/// Helper class for fetching metadata from Google Cloud Platform metadata service.
/// </summary>
public static class GcpMetadataHelper
{
    private static readonly HttpClient HttpClient = new HttpClient
    {
        Timeout = TimeSpan.FromSeconds(5) // Short timeout since metadata service should be fast
    };

    /// <summary>
    /// Fetches the Google Cloud Project ID from the metadata service.
    /// </summary>
    /// <param name="logger">Optional logger for diagnostic information.</param>
    /// <returns>The project ID if available, otherwise null.</returns>
    public static async Task<string?> GetProjectIdAsync(ILogger? logger = null)
    {
        try
        {
            const string metadataUrl = "http://metadata.google.internal/computeMetadata/v1/project/project-id";

            using var request = new HttpRequestMessage(HttpMethod.Get, metadataUrl);
            request.Headers.Add("Metadata-Flavor", "Google");

            logger?.LogDebug("Attempting to fetch project ID from GCP metadata service");

            using var response = await HttpClient.SendAsync(request);

            if (response.IsSuccessStatusCode)
            {
                var projectId = await response.Content.ReadAsStringAsync();
                logger?.LogDebug("Successfully retrieved project ID from metadata service: {ProjectId}", projectId);
                return projectId.Trim();
            }

            logger?.LogWarning("Metadata service returned non-success status: {StatusCode}", response.StatusCode);
            return null;
        }
        catch (HttpRequestException ex)
        {
            logger?.LogDebug(ex, "Failed to connect to GCP metadata service (likely not running in GCP)");
            return null;
        }
        catch (TaskCanceledException ex) when (ex.InnerException is TimeoutException)
        {
            logger?.LogDebug(ex, "Timeout while fetching project ID from metadata service");
            return null;
        }
        catch (Exception ex)
        {
            logger?.LogWarning(ex, "Unexpected error while fetching project ID from metadata service");
            return null;
        }
    }

    /// <summary>
    /// Gets the Google Cloud Project ID with fallback logic:
    /// 1. From GCP metadata service (when running in GCP)
    /// 2. From configuration "GCP:ProjectId"
    /// 3. From environment variable "GOOGLE_CLOUD_PROJECT"
    /// 4. Returns "unknown" as final fallback
    /// </summary>
    /// <param name="configuration">The application configuration.</param>
    /// <param name="logger">Optional logger for diagnostic information.</param>
    /// <returns>The project ID or "unknown" if not found.</returns>
    public static async Task<string> GetProjectIdWithFallbackAsync(IConfiguration configuration, ILogger? logger = null)
    {
        // Try metadata service first (when running in GCP)
        var projectIdFromMetadata = await GetProjectIdAsync(logger);
        if (!string.IsNullOrEmpty(projectIdFromMetadata))
        {
            logger?.LogInformation("Using project ID from GCP metadata service: {ProjectId}", projectIdFromMetadata);
            return projectIdFromMetadata;
        }

        // Fallback to configuration
        var projectIdFromConfig = configuration["GCP:ProjectId"];
        if (!string.IsNullOrEmpty(projectIdFromConfig))
        {
            logger?.LogInformation("Using project ID from configuration: {ProjectId}", projectIdFromConfig);
            return projectIdFromConfig;
        }

        // Fallback to environment variable
        var projectIdFromEnv = Environment.GetEnvironmentVariable("GOOGLE_CLOUD_PROJECT");
        if (!string.IsNullOrEmpty(projectIdFromEnv))
        {
            logger?.LogInformation("Using project ID from environment variable: {ProjectId}", projectIdFromEnv);
            return projectIdFromEnv;
        }

        logger?.LogWarning("Could not determine GCP project ID from any source, using 'unknown'");
        return "unknown";
    }
}
