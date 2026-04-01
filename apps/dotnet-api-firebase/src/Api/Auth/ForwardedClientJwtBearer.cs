namespace DotnetApiFirebase.Auth;

/// <summary>
/// When a front door (e.g. Google API Gateway with backend auth) forwards requests to Cloud Run,
/// the original client JWT is often in <c>X-Forwarded-Authorization</c> while <c>Authorization</c>
/// carries the gateway identity token. Use this in <see cref="Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents.OnMessageReceived"/>
/// so in-process validation uses the client JWT; if the header is absent, JwtBearer falls back to <c>Authorization</c>.
/// </summary>
public static class ForwardedClientJwtBearer
{
    public const string ForwardedAuthorizationHeaderName = "X-Forwarded-Authorization";

    /// <summary>
    /// Returns the raw JWT string if <c>X-Forwarded-Authorization</c> is present and non-empty;
    /// strips a leading <c>Bearer </c> prefix when present. Otherwise returns null so JwtBearer uses <c>Authorization</c>.
    /// </summary>
    public static string? ReadClientJwtForJwtBearer(HttpRequest request)
    {
        if (!request.Headers.TryGetValue(ForwardedAuthorizationHeaderName, out var values))
        {
            return null;
        }

        var raw = values.ToString();
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        var trimmed = raw.Trim();
        const string bearerPrefix = "Bearer ";
        if (trimmed.StartsWith(bearerPrefix, StringComparison.OrdinalIgnoreCase))
        {
            trimmed = trimmed[bearerPrefix.Length..].Trim();
        }

        return string.IsNullOrEmpty(trimmed) ? null : trimmed;
    }
}
