import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

final _kGentleDuration = Duration(milliseconds: 350);
final _kNormalDuration = Duration(milliseconds: 500);
final _kSubtleDuration = Duration(milliseconds: 300);
final _kSlowDuration = Duration(milliseconds: 200);

class CardDemonstrationDialog extends StatelessWidget {
  final cardAnimationContainerWidth = 342.0;
  final cardAnimationContainerHeight = 399.0;

  const CardDemonstrationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(),
        const SizedBox(height: 32),
        ClipRect(
          child: SizedBox(
            width: cardAnimationContainerWidth,
            height: cardAnimationContainerHeight,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: CardReader(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 20,
        children: [
          Text(
            'Pay in-store with your PIN to activate contactless',
            style: TextStyle(
              color: const Color(0xFF08080C) /* content-heading-default */,
              fontSize: 22,
              fontFamily: 'General Sans',
              fontWeight: FontWeight.w700,
              height: 1.20,
              letterSpacing: 0.30,
            ),
          ),
          Text(
            'Or withdraw cash from an ATM. You only have to do this the first time.',
            style: TextStyle(
              color: const Color(0xFF3B4454) /* content-subtext-default */,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.54,
              letterSpacing: -0.09,
            ),
          ),
        ],
      ),
    );
  }
}

class CardReader extends StatefulWidget {
  const CardReader({super.key});

  @override
  State<CardReader> createState() => _CardReaderState();
}

class _CardReaderState extends State<CardReader> with TickerProviderStateMixin {
  late AnimationController _readerController;
  late AnimationController _cardController;
  late Animation<double> _readerAnimation;
  late Animation<double> _cardAnimation;

  final _dialerController = DialerController();
  Curve _activeReaderCurve = GentleBackCurve();

  final double _cardPositionStart = 0;
  final double _cardPositionEnd = 300;

  @override
  void initState() {
    super.initState();
    _readerController = AnimationController(
      vsync: this,
      duration: _kGentleDuration,
    );
    _cardController = AnimationController(
      vsync: this,
      duration: _kGentleDuration,
    );
    _readerAnimation = Tween<double>(
      begin: -300,
      end: 0,
    ).animate(_readerController);
    _cardAnimation = Tween<double>(
      begin: _cardPositionStart,
      end: _cardPositionEnd,
    ).animate(
      CurvedAnimation(parent: _cardController, curve: GentleBackCurve()),
    );
    Future.delayed(_kGentleDuration, () {
      if (!mounted) return;
      _readerController.forward();
      _cardController.forward();
    });

    _readerAnimation.addStatusListener(_readerStatusListener);
    _cardAnimation.addStatusListener(_cardStatusListener);
  }

  void _readerStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      Future.delayed(_kSubtleDuration, () {
        _activeReaderCurve = GentleBackCurve();
        _cardController.forward();
        _readerController.forward();
      });
    }
  }

  void _cardStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      Future.delayed(_kNormalDuration, () {
        if (!mounted) return;
        final targetTweenValue = 12.0;
        final normalizedValue = targetTweenValue / _cardPositionEnd;
        _cardController.animateBack(normalizedValue).then((v) {
          Future.delayed(_kSlowDuration, () {
            _dialerController.begin().then((_) {
              if (!mounted) return;
              _activeReaderCurve = Curves.linear;
              _readerController
                  .animateBack(0, duration: Duration(milliseconds: 150))
                  .then((_) => _activeReaderCurve = GentleBackCurve());
              _cardController.animateBack(
                0,
                duration: _kSubtleDuration,
                curve: GentleBackCurve(),
              );
            });
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildCardView(), _buildCardReaderContainer()]);
  }

  Widget _buildCardReaderContainer() {
    return AnimatedBuilder(
      animation: _readerAnimation,
      builder: (context, child) {
        final curvedValue = _activeReaderCurve.transform(
          _readerController.value,
        );
        final position = Tween<double>(
          begin: -310,
          end: 0,
        ).transform(curvedValue);

        return Transform.translate(offset: Offset(-1, position), child: child);
      },
      child: Stack(
        children: [
          Image.asset('assets/png/card-reader.png'),
          Positioned(
            top: 0,
            left: 30,
            child: Dialer(controller: _dialerController),
          ),
        ],
      ),
    );
  }

  Widget _buildCardView() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardAnimation.value),
          child: child,
        );
      },
      child: Transform.rotate(
        angle: 4.72,
        child: SvgPicture.asset(
          width: 210.33,
          height: 346,
          'assets/svg/card.svg',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _readerController.removeStatusListener(_readerStatusListener);
    _cardController.removeStatusListener(_cardStatusListener);
    _readerController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}

class Dialer extends StatelessWidget {
  final DialerController? controller;

  const Dialer({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => controller ?? DialerController(),
      builder: (context, child) {
        final keys = context.read<DialerController>().keys;
        return Selector<DialerController, String?>(
          builder: (context, activeKey, child) {
            return Container(
              width: 283,
              height: 240,
              color: Color(0XFFE8EAED),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: keys.length,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 4,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.9,
                ),
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final isActive = activeKey == key;
                  if (key == 'del') {
                    return Icon(Icons.backspace_outlined, color: Colors.black);
                  }

                  return IgnorePointer(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        color: isActive ? Colors.grey.shade400 : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade600,
                            blurRadius: 0,
                            offset: const Offset(0, 0.6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          key,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                            fontFamily: 'Work Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          selector: (context, vm) => vm.activeKey,
        );
      },
    );
  }
}

class DialerController extends ChangeNotifier {
  final List<String> keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '•',
    '0',
    'del',
  ];
  String? activeKey;

  final pressedKeys = ['7', '8', '2', '5'];

  Future<void> _startFakeKeypressAnimation() async {
    for (int i = 0; i < pressedKeys.length; i++) {
      setActiveKey(pressedKeys[i]);
      await Future.delayed(Duration(milliseconds: 400));
      setActiveKey(null);
      if (i == pressedKeys.length - 1) {
        await Future.delayed(Duration(milliseconds: 100));
      } else {
        await Future.delayed(Duration(milliseconds: 400));
      }
    }
  }

  void setActiveKey(String? key) {
    activeKey = key;
    if (hasListeners) {
      notifyListeners();
    }
  }

  Future<void> begin() {
    if (hasListeners) {
      return _startFakeKeypressAnimation();
    }
    return Future.value();
  }
}

class GentleBackCurve extends Curve {
  final double overshoot;

  const GentleBackCurve({this.overshoot = 1});

  @override
  double transform(double t) {
    final s = overshoot;
    t = t - 1.0;
    return t * t * ((s + 1) * t + s) + 1.0;
  }
}
