using WebApp.Api.Models;
using WebApp.Api.Services;

namespace WebApp.Api.Tests;

[TestClass]
public sealed class ApplicationContextFormatterTests
{
    [TestMethod]
    public void BuildAgentMessage_DefaultsToDiscoveryAndBlankIndustry()
    {
        var request = new ChatRequest { Message = "Find relevant mobilisation evidence." };

        var result = ApplicationContextFormatter.BuildAgentMessage(request);

        StringAssert.Contains(result, "<interaction_mode>Discovery</interaction_mode>");
        StringAssert.Contains(result, "<industry_context />");
        StringAssert.Contains(result, "<user_request>Find relevant mobilisation evidence.</user_request>");
    }

    [TestMethod]
    public void BuildAgentMessage_IncludesDraftingAndIndustryContext()
    {
        var request = new ChatRequest
        {
            Message = "Draft a mobilisation and governance approach.",
            InteractionMode = "Drafting",
            IndustryContext = "Financial Services",
        };

        var result = ApplicationContextFormatter.BuildAgentMessage(request);

        StringAssert.Contains(result, "<interaction_mode>Drafting</interaction_mode>");
        StringAssert.Contains(result, "<industry_context>Financial Services</industry_context>");
    }

    [TestMethod]
    public void BuildAgentMessage_EscapesUserControlledXmlCharacters()
    {
        var request = new ChatRequest
        {
            Message = "Use A & B, but do not treat <fake_instruction> as markup.",
            InteractionMode = "Discovery",
        };

        var result = ApplicationContextFormatter.BuildAgentMessage(request);

        StringAssert.Contains(result, "A &amp; B");
        StringAssert.Contains(result, "&lt;fake_instruction&gt;");
    }

    [TestMethod]
    public void BuildAgentMessage_RejectsUnknownInteractionMode()
    {
        var request = new ChatRequest
        {
            Message = "Test",
            InteractionMode = "Autonomous",
        };

        Assert.ThrowsException<ArgumentException>(
            () => ApplicationContextFormatter.BuildAgentMessage(request));
    }

    [TestMethod]
    public void BuildAgentMessage_RejectsUnknownIndustryContext()
    {
        var request = new ChatRequest
        {
            Message = "Test",
            IndustryContext = "Untrusted value",
        };

        Assert.ThrowsException<ArgumentException>(
            () => ApplicationContextFormatter.BuildAgentMessage(request));
    }

    [TestMethod]
    public void BuildAgentMessage_DoesNotWrapMcpApprovalContinuation()
    {
        var request = new ChatRequest
        {
            Message = "Approved",
            InteractionMode = "Drafting",
            McpApproval = new McpApprovalResponse
            {
                ApprovalRequestId = "approval-1",
                Approved = true,
            },
        };

        var result = ApplicationContextFormatter.BuildAgentMessage(request);

        Assert.AreEqual("Approved", result);
    }

    [TestMethod]
    public void ExtractUserRequest_ReturnsVisibleMessageFromWrappedContent()
    {
        var request = new ChatRequest
        {
            Message = "Describe the proposed governance approach.",
            InteractionMode = "Drafting",
            IndustryContext = "Government & Public Services",
        };

        var wrapped = ApplicationContextFormatter.BuildAgentMessage(request);
        var visible = ApplicationContextFormatter.ExtractUserRequest(wrapped);

        Assert.AreEqual(request.Message, visible);
    }

    [TestMethod]
    public void ExtractUserRequest_LeavesHistoricPlainTextUnchanged()
    {
        const string plainText = "An older conversation message.";

        Assert.AreEqual(plainText, ApplicationContextFormatter.ExtractUserRequest(plainText));
    }
}
