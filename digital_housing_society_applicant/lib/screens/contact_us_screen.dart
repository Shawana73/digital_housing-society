import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/branded_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _name.text = user?.displayName ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.saveContactMessage({
        'applicantId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'subject': _subject.text.trim(),
        'message': _message.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your message has been sent to society support.')));
      _subject.clear();
      _message.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message could not be sent. Please try again.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 760;
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: BrandedImageBackground(
        imagePath: AppAssets.courtyardBackground,
        overlayOpacity: .34,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Container(
                  padding: EdgeInsets.all(wide ? 28 : 18),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .96),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: AppColors.premiumShadow(blurRadius: 30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Get in Touch', style: AppTextStyles.headingLarge.copyWith(color: AppColors.infoBlue)),
                      const SizedBox(height: 8),
                      Text('We are here to help with your application, documents, payment and balloting queries.', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 22),
                      if (wide)
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _infoPanel()), const SizedBox(width: 28), Expanded(child: _form())])
                      else
                        Column(children: [_infoPanel(), const SizedBox(height: 22), _form()]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Send a Message', style: AppTextStyles.headingMedium.copyWith(color: AppColors.deepPurple)),
        const SizedBox(height: 8),
        Text('Fill in the form below and our support team will review your request.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),
        AppTextField(label: 'Full Name', hint: 'Enter your name', controller: _name, prefixIcon: Icons.person_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
        const SizedBox(height: 12),
        AppTextField(label: 'Email Address', hint: 'you@example.com', controller: _email, prefixIcon: Icons.email_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'Email is required' : null),
        const SizedBox(height: 12),
        AppTextField(label: 'Subject', hint: 'Application / Payment / Balloting', controller: _subject, prefixIcon: Icons.subject_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'Subject is required' : null),
        const SizedBox(height: 12),
        AppTextField(label: 'Message', hint: 'Go ahead, we are listening...', controller: _message, prefixIcon: Icons.message_rounded, maxLines: 6, validator: (v) => v == null || v.trim().length < 10 ? 'Message must be at least 10 characters' : null),
        const SizedBox(height: 18),
        PrimaryGradientButton(text: 'Submit', icon: Icons.send_rounded, isLoading: _loading, onPressed: _submit),
      ]),
    );
  }

  Widget _infoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.premiumShadow(opacity: .25),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 76, height: 76, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22)), child: Image.asset(AppAssets.logo, fit: BoxFit.contain)),
        const SizedBox(height: 20),
        Text('Digital Housing Society Support', style: AppTextStyles.headingMedium.copyWith(color: AppColors.white)),
        const SizedBox(height: 8),
        Text('Reach society support for application, payment, document and balloting queries.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .82))),
        const SizedBox(height: 22),
        _contactItem(Icons.location_on_rounded, 'Bluearea, Islamabad, Pakistan'),
        _contactItem(Icons.phone_rounded, '+92-320-0420365'),
        _contactItem(Icons.email_rounded, 'support@digitalhousing.pk'),
        const SizedBox(height: 12),
        Row(children: [
          _social(Icons.public_rounded),
          const SizedBox(width: 10),
          _social(Icons.alternate_email_rounded),
          const SizedBox(width: 10),
          _social(Icons.language_rounded),
        ]),
      ]),
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: AppColors.white.withValues(alpha: .18), child: Icon(icon, color: AppColors.white)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.labelBold.copyWith(color: AppColors.white))),
      ]),
    );
  }

  Widget _social(IconData icon) => Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.white));
}
