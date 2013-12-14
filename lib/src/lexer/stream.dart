part of lexer;

abstract class TokenStream extends Stream<Token> {
  /// Input stream where characters are coming in.
  Stream<String> inputStream;

  /// Output stream where tokens are coming out.
  StreamController<Token> outputStream;

  /// Subscription on [inputStream] while subscribed.
  StreamSubscription<String> _subscription;

  TokenStream(this.inputStream){
    outputStream = new StreamController<Token>(
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: _onCancel);
  }

  /// Implements [Stream.listen]
  StreamSubscription<Token> listen(void onData(Token token),
                                    { void onError(Error error),
                                      void onDone(),
                                      bool cancelOnError }) {
    return outputStream.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  _onListen() {
    _subscription = inputStream.listen(_onData,
                                   onError: outputStream.addError,
                                   onDone: _onDone);
  }
  _onResume() {
    _subscription.pause();
  }
  _onCancel() {
    _subscription.cancel();
    _subscription = null;
  }
  _onPause() {
    _subscription.resume();
  }

  _onData(String ch);
  _onDone();
}
