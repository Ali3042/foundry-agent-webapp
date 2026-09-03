using System.Xml.Linq;
using WebApp.Api.Models;

namespace WebApp.Api.Services;

/// <summary>
/// Validates ShareCloud's request-level UI context and serializes it for the agent.
/// Keeping this logic server-side prevents arbitrary client values from being treated as
/// trusted application context and keeps the visible user message clean in the web app.
/// </summary>
public static class ApplicationContextFormatter
{
    public const string DefaultInteractionMode = "Discovery";

    private static readonly HashSet<string> AllowedInteractionModes = new(StringComparer.Ordinal)
    {
        "Discovery",
        "Drafting",
    };

    private static readonly HashSet<string> AllowedIndustryContexts = new(StringComparer.Ordinal)
    {
        "Financial Services",
        "Government & Public Services",
        "Energy, Utilities & Resources",
        "Consumer Markets",
        "Industrial Manufacturing & Automotive",
        "Health Industries",
        "Technology, Media & Telecommunications",
        "Other",
    };

    /// <summary>
    /// Builds the message passed to the Foundry agent. MCP approval continuations are left
    /// untouched because they resume an existing response rather than create a new user task.
    /// </summary>
    public static string BuildAgentMessage(ChatRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (request.McpApproval is not null)
        {
            return request.Message;
        }

        var interactionMode = string.IsNullOrWhiteSpace(request.InteractionMode)
            ? DefaultInteractionMode
            : request.InteractionMode.Trim();

        if (!AllowedInteractionModes.Contains(interactionMode))
        {
            throw new ArgumentException(
                $"Invalid interaction mode '{request.InteractionMode}'.",
                nameof(ChatRequest.InteractionMode));
        }

        var industryContext = request.IndustryContext?.Trim() ?? string.Empty;
        if (industryContext.Length > 0 && !AllowedIndustryContexts.Contains(industryContext))
        {
            throw new ArgumentException(
                $"Invalid industry context '{request.IndustryContext}'.",
                nameof(ChatRequest.IndustryContext));
        }

        var applicationContext = new XElement(
            "application_context",
            new XElement("interaction_mode", interactionMode),
            new XElement("industry_context", industryContext));

        var userRequest = new XElement("user_request", request.Message);

        return $"{applicationContext}{Environment.NewLine}{Environment.NewLine}{userRequest}";
    }

    /// <summary>
    /// Removes the server-generated wrapper before conversation history is returned to the UI.
    /// Plain historic messages are returned unchanged.
    /// </summary>
    public static string ExtractUserRequest(string message)
    {
        if (string.IsNullOrWhiteSpace(message)
            || !message.Contains("<application_context>", StringComparison.Ordinal)
            || !message.Contains("<user_request>", StringComparison.Ordinal))
        {
            return message;
        }

        try
        {
            var root = XElement.Parse($"<sharecloud_message>{message}</sharecloud_message>");
            return root.Element("user_request")?.Value ?? message;
        }
        catch
        {
            // Conversation history should remain available even if it contains an older or
            // manually-authored message that resembles the ShareCloud wrapper.
            return message;
        }
    }
}
