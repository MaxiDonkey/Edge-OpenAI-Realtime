# Realtime Sources

The `source/realtime` folder contains the **Realtime core implementation**.  
It is designed to be independent from the VCL/WebView2 adapter, so it can be reused in any Delphi project without modification.

## Version alignment
As of **September 2025**, the implementation is fully aligned with the **latest OpenAI Realtime API**.  
This includes:
- **Functions**: the ability to invoke functions during a realtime session.  
- **Remote MCP tools**: integration with external MCP servers through the Realtime API.  

## Independence
The Realtime sources are **self-contained**:
- They do not depend on the VCL demo or on the Edge/WebView2 adapter.  
- They can be directly included into another Delphi project, regardless of the UI framework.  

In this project, they are consumed by the `TEdgeRealtimeControl` component, but the same code can also be reused in a **console app**, a **service**, or any other client that requires direct access to the Realtime API.
