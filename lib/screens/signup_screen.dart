import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/otp_service.dart';
import 'home_screen.dart';
import 'dart:math';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  final _otpService = OTPService();
  bool _isLoading = false;
  bool _showOTPField = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedBloodGroup;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _otpService.sendOTP(_emailController.text.trim());
      
      if (!mounted) return;

      if (success) {
        setState(() {
          _showOTPField = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final otpVerified = await _otpService.verifyOTP(
        _emailController.text.trim(),
        _otpController.text,
      );

      if (!otpVerified) {
        if (!mounted) return;
        
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedBloodGroup,
      );

      if (!mounted) return;

      if (success) {
        await _otpService.clearOTP(_emailController.text.trim());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBloodGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is your blood group?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bloodtype,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Select your blood group',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bloodGroups.map((bloodGroup) {
                        final isSelected = _selectedBloodGroup == bloodGroup;
                        return ChoiceChip(
                          label: Text(
                            bloodGroup,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedBloodGroup = selected ? bloodGroup : null;
                            });
                            if (selected) {
                              _animationController.forward(from: 0.0);
                            }
                          },
                          selectedColor: Colors.red[900],
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? Colors.red[900]! : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Animated Human Figure
            Container(
              width: 100,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Human Body
                  CustomPaint(
                    size: const Size(70, 140),
                    painter: HumanBodyPainter(
                      bloodGroup: _selectedBloodGroup,
                      animation: _animation,
                    ),
                  ),
                  // Blood Group Text
                  if (_selectedBloodGroup != null)
                    Positioned(
                      bottom: 4,
                      child: Text(
                        _selectedBloodGroup!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[900],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bloodtype,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Gmail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your Gmail';
                      }
                      if (!value.contains('@gmail.com')) {
                        return 'Please enter a valid Gmail address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Blood Group Selection
                  _buildBloodGroupSelector(),
                  const SizedBox(height: 24),
                  // OTP Field (shown only after sending OTP)
                  if (_showOTPField) ...[
                    TextFormField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        prefixIcon: const Icon(Icons.security),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length != 6) {
                          return 'OTP must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Send OTP or Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : (_showOTPField ? _register : _sendOTP),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _showOTPField ? 'Register' : 'Send OTP',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[900],
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HumanBodyPainter extends CustomPainter {
  final String? bloodGroup;
  final Animation<double> animation;

  HumanBodyPainter({
    required this.bloodGroup,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw head with more realistic proportions and animation
    final headRadius = size.width * 0.15;
    final headOffset = Offset(size.width / 2, size.height * 0.2);
    
    // Draw face features
    final facePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Head outline with subtle pulse
    canvas.drawCircle(
      headOffset,
      headRadius * (1 + animation.value * 0.03),
      paint,
    );
    
    // Eyes
    final eyeRadius = headRadius * 0.2;
    final leftEye = Offset(size.width / 2 - headRadius * 0.3, size.height * 0.18);
    final rightEye = Offset(size.width / 2 + headRadius * 0.3, size.height * 0.18);
    canvas.drawCircle(leftEye, eyeRadius, facePaint);
    canvas.drawCircle(rightEye, eyeRadius, facePaint);
    
    // Smile animation
    final smilePath = Path();
    final smileStart = Offset(size.width / 2 - headRadius * 0.4, size.height * 0.22);
    final smileEnd = Offset(size.width / 2 + headRadius * 0.4, size.height * 0.22);
    final smileControl = Offset(
      size.width / 2,
      size.height * 0.22 + sin(animation.value * 2 * 3.14159) * 5,
    );
    smilePath.moveTo(smileStart.dx, smileStart.dy);
    smilePath.quadraticBezierTo(
      smileControl.dx,
      smileControl.dy,
      smileEnd.dx,
      smileEnd.dy,
    );
    canvas.drawPath(smilePath, facePaint);

    // Draw neck
    final neckStart = Offset(size.width / 2, size.height * 0.3);
    final neckEnd = Offset(size.width / 2, size.height * 0.35);
    canvas.drawLine(neckStart, neckEnd, paint);

    // Draw torso with more natural shape
    final torsoPath = Path();
    final shoulderWidth = size.width * 0.4;
    final waistWidth = size.width * 0.3;
    final torsoHeight = size.height * 0.3;
    
    torsoPath.moveTo(size.width / 2 - shoulderWidth / 2, size.height * 0.35);
    torsoPath.lineTo(size.width / 2 - waistWidth / 2, size.height * 0.35 + torsoHeight);
    torsoPath.lineTo(size.width / 2 + waistWidth / 2, size.height * 0.35 + torsoHeight);
    torsoPath.lineTo(size.width / 2 + shoulderWidth / 2, size.height * 0.35);
    torsoPath.close();
    
    // Add subtle breathing animation
    final scale = 1 + sin(animation.value * 2 * 3.14159) * 0.02;
    final matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(
        (size.width / 2) * (1 - scale),
        (size.height * 0.35) * (1 - scale),
      );
    canvas.transform(matrix.storage);
    canvas.drawPath(torsoPath, paint);
    canvas.transform(Matrix4.identity().storage);

    // Draw arms with more natural movement
    final armLength = size.height * 0.3;
    final armAngle = sin(animation.value * 2 * 3.14159) * 0.3;
    
    // Left arm
    final leftShoulder = Offset(size.width / 2 - shoulderWidth / 2, size.height * 0.35);
    final leftElbow = Offset(
      leftShoulder.dx - armLength * 0.4 * cos(armAngle),
      leftShoulder.dy + armLength * 0.4 * sin(armAngle),
    );
    final leftHand = Offset(
      leftElbow.dx - armLength * 0.6 * cos(armAngle + 0.2),
      leftElbow.dy + armLength * 0.6 * sin(armAngle + 0.2),
    );
    canvas.drawLine(leftShoulder, leftElbow, paint);
    canvas.drawLine(leftElbow, leftHand, paint);
    
    // Right arm
    final rightShoulder = Offset(size.width / 2 + shoulderWidth / 2, size.height * 0.35);
    final rightElbow = Offset(
      rightShoulder.dx + armLength * 0.4 * cos(armAngle),
      rightShoulder.dy + armLength * 0.4 * sin(armAngle),
    );
    final rightHand = Offset(
      rightElbow.dx + armLength * 0.6 * cos(armAngle + 0.2),
      rightElbow.dy + armLength * 0.6 * sin(armAngle + 0.2),
    );
    canvas.drawLine(rightShoulder, rightElbow, paint);
    canvas.drawLine(rightElbow, rightHand, paint);

    // Draw legs with more natural walking motion
    final legLength = size.height * 0.4;
    final legAngle = sin(animation.value * 2 * 3.14159) * 0.4;
    
    // Left leg
    final leftHip = Offset(size.width / 2 - waistWidth / 4, size.height * 0.65);
    final leftKnee = Offset(
      leftHip.dx - legLength * 0.4 * cos(legAngle),
      leftHip.dy + legLength * 0.4 * sin(legAngle),
    );
    final leftFoot = Offset(
      leftKnee.dx - legLength * 0.6 * cos(legAngle + 0.2),
      leftKnee.dy + legLength * 0.6 * sin(legAngle + 0.2),
    );
    canvas.drawLine(leftHip, leftKnee, paint);
    canvas.drawLine(leftKnee, leftFoot, paint);
    
    // Right leg
    final rightHip = Offset(size.width / 2 + waistWidth / 4, size.height * 0.65);
    final rightKnee = Offset(
      rightHip.dx + legLength * 0.4 * cos(legAngle),
      rightHip.dy + legLength * 0.4 * sin(legAngle),
    );
    final rightFoot = Offset(
      rightKnee.dx + legLength * 0.6 * cos(legAngle + 0.2),
      rightKnee.dy + legLength * 0.6 * sin(legAngle + 0.2),
    );
    canvas.drawLine(rightHip, rightKnee, paint);
    canvas.drawLine(rightKnee, rightFoot, paint);

    // Draw blood flow animation if blood group is selected
    if (bloodGroup != null) {
      final bloodPaint = Paint()
        ..color = Colors.red[900]!.withOpacity(animation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Draw detailed heart with chambers
      final heartSize = 20.0 * (1 + animation.value * 0.2);
      final heartPath = Path();
      
      // Main heart shape
      heartPath.moveTo(size.width / 2, size.height * 0.3);
      heartPath.cubicTo(
        size.width / 2 + heartSize,
        size.height * 0.3 - heartSize,
        size.width / 2 + heartSize * 2,
        size.height * 0.3 + heartSize,
        size.width / 2,
        size.height * 0.3 + heartSize * 2,
      );
      heartPath.cubicTo(
        size.width / 2 - heartSize * 2,
        size.height * 0.3 + heartSize,
        size.width / 2 - heartSize,
        size.height * 0.3 - heartSize,
        size.width / 2,
        size.height * 0.3,
      );
      
      // Add heart chambers
      final chamberSize = heartSize * 0.3;
      heartPath.addOval(Rect.fromCircle(
        center: Offset(size.width / 2 - chamberSize, size.height * 0.3 + chamberSize),
        radius: chamberSize,
      ));
      heartPath.addOval(Rect.fromCircle(
        center: Offset(size.width / 2 + chamberSize, size.height * 0.3 + chamberSize),
        radius: chamberSize,
      ));
      
      canvas.drawPath(heartPath, bloodPaint);

      // Draw detailed circulatory system
      final circulatoryPath = Path();
      
      // Main arteries
      circulatoryPath.moveTo(size.width / 2, size.height * 0.3 + heartSize);
      circulatoryPath.cubicTo(
        size.width / 2 + 15,
        size.height * 0.4,
        size.width / 2 - 15,
        size.height * 0.5,
        size.width / 2,
        size.height * 0.6,
      );
      
      // Branching veins
      for (var i = 0; i < 3; i++) {
        final branchAngle = i * 0.5;
        circulatoryPath.moveTo(size.width / 2, size.height * 0.5);
        circulatoryPath.cubicTo(
          size.width / 2 + 10 * cos(branchAngle),
          size.height * 0.55,
          size.width / 2 - 10 * cos(branchAngle),
          size.height * 0.6,
          size.width / 2,
          size.height * 0.65,
        );
      }
      
      canvas.drawPath(circulatoryPath, bloodPaint);

      // Add pulsing blood cells
      final cellCount = 5;
      for (var i = 0; i < cellCount; i++) {
        final cellSize = 6.0 * (1 + animation.value * 0.5);
        final cellOffset = Offset(
          size.width / 2 + (i - cellCount / 2) * 15,
          size.height * 0.7 + sin(animation.value * 2 * 3.14159 + i) * 8,
        );
        
        // Draw cell membrane
        canvas.drawCircle(cellOffset, cellSize, bloodPaint);
        
        // Draw cell nucleus
        final nucleusPaint = Paint()
          ..color = Colors.red[900]!.withOpacity(animation.value * 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(cellOffset, cellSize * 0.4, nucleusPaint);
      }
    }
  }

  @override
  bool shouldRepaint(HumanBodyPainter oldDelegate) {
    return bloodGroup != oldDelegate.bloodGroup || animation != oldDelegate.animation;
  }
} 