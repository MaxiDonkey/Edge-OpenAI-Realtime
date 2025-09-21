unit WebRTC.Core;

interface

uses
  System.SysUtils;

type
  IPageOffer = interface
    ['{185141A7-CDCB-4DAB-8D63-92C9939A7831}']
    /// <summary>
    /// Initiates a WebRTC connection in the page context using the specified URL and bearer token.
    /// </summary>
    /// <param name="Url">
    /// The signaling server or endpoint URL used to establish the connection.
    /// </param>
    /// <param name="Bearer">
    /// The bearer token or authentication string used for the connection.
    /// </param>
    /// <returns>
    /// <c>True</c> if the connection process was successfully initiated; otherwise, <c>False</c>.
    /// </returns>
    /// <remarks>
    /// This method delegates the connection setup to the JavaScript environment within the page.
    /// It should be called after the page is fully loaded and the WebRTC context is ready.
    /// </remarks>
    function ConnectInPage(const Url, Bearer: string): Boolean;
  end;

  IDataChannel = interface
    ['{2DB2F2D4-B808-44F0-8E5C-0DDC28EC8C2E}']
    function Label_: string;
    /// <summary>
    /// String Enum: connecting|open|closing|closed
    /// </summary>
    function ReadyState: string;

    /// <summary>
    /// Sends a UTF-8 text message over the data channel to the remote peer.
    /// </summary>
    /// <param name="Text">
    /// The string message to send. This should be UTF-8 encoded and must not be empty.
    /// </param>
    /// <remarks>
    /// This method transmits textual data to the connected peer using the underlying WebRTC data channel.
    /// If the data channel is not open, the message may be discarded or result in an error on the JavaScript side.
    /// Use <see cref="ReadyState"/> to check the current status of the data channel before sending.
    /// </remarks>
    procedure Send(const Text: string); overload;

    /// <summary>
    /// Sends a binary message over the data channel to the remote peer.
    /// </summary>
    /// <param name="Bytes">
    /// The byte array containing the binary data to send. May be empty, but should not be nil.
    /// </param>
    /// <remarks>
    /// This method transmits binary data to the connected peer using the underlying WebRTC data channel.
    /// Binary messages are suitable for transmitting files, serialized objects, or any non-textual data.
    /// If the data channel is not open, the message may be discarded or result in an error on the JavaScript side.
    /// Use <see cref="ReadyState"/> to check the current status of the data channel before sending.
    /// </remarks>
    procedure Send(const Bytes: TBytes); overload;

    /// <summary>
    /// Closes the data channel and releases any associated resources.
    /// </summary>
    /// <remarks>
    /// Calling this method initiates the closure of the data channel connection with the remote peer.
    /// Once closed, no further messages can be sent or received on this channel.
    /// Closing a data channel is an idempotent operation; repeated calls have no additional effect.
    /// </remarks>
    procedure Close;
  end;

  IPeerEvents = interface
    ['{995EC17B-82EB-441C-99EE-371D6D446422}']
    /// <summary>
    /// Invoked when the peer connection has been successfully established.
    /// </summary>
    /// <remarks>
    /// This event is triggered when the signaling and negotiation process completes and the connection becomes active.
    /// Use this callback to perform actions that depend on the connection being ready for data or media exchange.
    /// </remarks>
    procedure OnConnected;

    /// <summary>
    /// Invoked when the peer connection has been closed or terminated.
    /// </summary>
    /// <remarks>
    /// This event is triggered when the connection to the remote peer has been closed, either intentionally or due to an error.
    /// After this callback, no further data or media can be exchanged over the connection.
    /// </remarks>
    procedure OnClosed;

    /// <summary>
    /// Invoked when the state of the peer connection changes.
    /// </summary>
    /// <param name="State">
    /// The new connection state as a string. Typical values include: "new", "connecting", "connected", "disconnected", "failed", or "closed".
    /// </param>
    /// <remarks>
    /// This event allows applications to monitor the lifecycle and health of the peer connection.
    /// Use this callback to update the UI or trigger actions in response to state transitions.
    /// </remarks>
    procedure OnStateChange(const State: string);

    /// <summary>
    /// Invoked when a new ICE candidate is discovered for the peer connection.
    /// </summary>
    /// <param name="CandidateLine">
    /// The candidate line string representing the ICE candidate.
    /// </param>
    /// <param name="SdpMid">
    /// The media stream identification (mid) associated with the candidate.
    /// </param>
    /// <param name="SdpMLineIndex">
    /// The index of the media description (m-line) in the SDP.
    /// </param>
    /// <remarks>
    /// Use this event to gather and send local ICE candidates to the remote peer during the negotiation process.
    /// This is essential for establishing the most optimal network path between peers.
    /// </remarks>
    procedure OnIceCandidate(const CandidateLine, SdpMid: string; SdpMLineIndex: Integer);

    /// <summary>
    /// Invoked when a new data channel is created by the remote peer.
    /// </summary>
    /// <param name="Ch">
    /// The <see cref="IDataChannel"/> instance representing the newly opened data channel.
    /// </param>
    /// <remarks>
    /// This event is triggered when the remote peer creates a data channel, allowing bidirectional data exchange.
    /// Use this callback to configure event handlers or process incoming data channels as needed.
    /// </remarks>
    procedure OnDataChannel(const Ch: IDataChannel);

    /// <summary>
    /// Invoked when a remote audio track becomes available on the peer connection.
    /// </summary>
    /// <remarks>
    /// This event is triggered when the remote peer adds an audio track to the connection.
    /// Use this callback to handle playback or further processing of the received audio stream.
    /// </remarks>
    procedure OnRemoteAudioTrack;

    /// <summary>
    /// Invoked when an error occurs in the peer connection or its underlying components.
    /// </summary>
    /// <param name="MessageText">
    /// A string describing the error that occurred. This may include diagnostic or contextual information.
    /// </param>
    /// <remarks>
    /// Use this event to log errors, display user notifications, or perform cleanup actions when the connection encounters a problem.
    /// </remarks>
    procedure OnError(const MessageText: string);
  end;

  IPeerConnection = interface
    ['{0714A459-B3CF-4BB8-9D22-73220E800A0A}']
    /// <summary>
    /// Registers an event sink to receive callbacks related to the peer connection lifecycle and events.
    /// </summary>
    /// <param name="Sink">
    /// The <see cref="IPeerEvents"/> implementation that will handle peer connection events.
    /// </param>
    /// <remarks>
    /// This method must be called to enable the reception of events such as connection state changes, incoming data channels, and errors.
    /// Passing <c>nil</c> will detach any previously registered event sink.
    /// </remarks>
    procedure SetEvents(const Sink: IPeerEvents);

    /// <summary>
    /// Actively creates a new data channel with the specified label for bidirectional data exchange.
    /// </summary>
    /// <param name="Label_">
    /// The label to assign to the data channel. This string is used to identify the channel.
    /// </param>
    /// <returns>
    /// An <see cref="IDataChannel"/> instance representing the newly created data channel.
    /// </returns>
    /// <remarks>
    /// Use this method to establish a custom data channel for transmitting text or binary data between peers.
    /// The label must be unique within the scope of the connection.
    /// </remarks>
    function CreateDataChannel(const Label_: string): IDataChannel;

    /// <summary>
    /// Attempts to create a session description offer (SDP) for initiating a WebRTC connection.
    /// </summary>
    /// <param name="Sdp">
    /// Output parameter that receives the generated session description offer as a string, if successful.
    /// </param>
    /// <returns>
    /// <c>True</c> if the offer was successfully created; otherwise, <c>False</c>.
    /// </returns>
    /// <remarks>
    /// Call this method on the initiating peer to start the negotiation process.
    /// The generated SDP should be sent to the remote peer as part of the WebRTC signaling exchange.
    /// </remarks>
    function TryCreateOffer(out Sdp: string): Boolean;

    /// <summary>
    /// Sets the local session description for the peer connection.
    /// </summary>
    /// <param name="Sdp">
    /// The session description (SDP) string to be applied locally.
    /// </param>
    /// <param name="Kind">
    /// The type of session description, typically "offer" or "answer". Defaults to "offer".
    /// </param>
    /// <remarks>
    /// Use this method to apply the local SDP after creating an offer or answer.
    /// Setting the local description is a necessary step in the WebRTC negotiation process.
    /// </remarks>
    procedure SetLocalDescription(const Sdp: string; const Kind: string = 'offer');

    /// <summary>
    /// Sets the remote session description for the peer connection.
    /// </summary>
    /// <param name="Sdp">
    /// The session description (SDP) string received from the remote peer.
    /// </param>
    /// <param name="Kind">
    /// The type of session description, typically "answer" or "offer". Defaults to "answer".
    /// </param>
    /// <remarks>
    /// Use this method to apply the remote peer's SDP during the WebRTC negotiation process.
    /// Setting the remote description is required to establish a successful connection.
    /// </remarks>
    procedure SetRemoteDescription(const Sdp: string; const Kind: string = 'answer');

    /// <summary>
    /// Adds a new ICE candidate to the peer connection for network negotiation.
    /// </summary>
    /// <param name="CandidateLine">
    /// The candidate line string representing the ICE candidate.
    /// </param>
    /// <param name="SdpMid">
    /// The media stream identification (mid) associated with the candidate.
    /// </param>
    /// <param name="SdpMLineIndex">
    /// The index of the media description (m-line) in the SDP to which this candidate applies.
    /// </param>
    /// <remarks>
    /// Use this method to provide ICE candidates received from the remote peer during the signaling phase.
    /// Proper exchange of ICE candidates is required for establishing the most effective connection path.
    /// </remarks>
    procedure AddIceCandidate(const CandidateLine, SdpMid: string; SdpMLineIndex: Integer);

    /// <summary>
    /// Attaches the local microphone to the peer connection for audio transmission.
    /// </summary>
    /// <remarks>
    /// Use this method to enable audio capture from the local device's microphone and transmit it to the remote peer.
    /// If media is not supported by the implementation, this method may be a no-op.
    /// </remarks>
    procedure AttachLocalMicrophone;

    /// <summary>
    /// Detaches the local microphone from the peer connection, stopping audio transmission.
    /// </summary>
    /// <remarks>
    /// Use this method to disable audio capture and transmission from the local device's microphone.
    /// If media is not supported by the implementation, this method may be a no-op.
    /// </remarks>
    procedure DetachLocalMicrophone;

    /// <summary>
    /// Returns the default data channel associated with the peer connection, if available.
    /// </summary>
    /// <returns>
    /// The <see cref="IDataChannel"/> instance representing the default or primary data channel, or <c>nil</c> if none is available.
    /// </returns>
    /// <remarks>
    /// Use this method to access the primary data channel for sending and receiving messages.
    /// If no data channel has been created or negotiated, this method may return <c>nil</c>.
    /// </remarks>
    function DataChannel: IDataChannel;

    /// <summary>
    /// Closes the peer connection and releases all associated resources.
    /// </summary>
    /// <remarks>
    /// This method initiates the closure of the connection to the remote peer.
    /// After calling this method, no further data or media can be exchanged, and all underlying resources will be cleaned up.
    /// Repeated calls to this method are safe and have no additional effect.
    /// </remarks>
    procedure Close;
  end;

  /// <summary>
  /// Factory injectable
  /// </summary>
  IWebRTCFactory = interface
    ['{46BFEB0A-2D8C-486E-9B9C-A740BD466EB3}']
    /// <summary>
    /// Free options: key/value on impl side (doesn't matter here)
    /// </summary>
    function CreatePeer(const Options: IInterface = nil): IPeerConnection;
  end;

implementation
end.

