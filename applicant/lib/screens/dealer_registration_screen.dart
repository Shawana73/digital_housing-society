import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../utils/formatters_validators.dart';
import '../widgets/responsive_shell.dart';

class DealerRegistrationScreen extends StatefulWidget {
  const DealerRegistrationScreen({super.key});

  @override
  State<DealerRegistrationScreen> createState() =>
      _DealerRegistrationScreenState();
}

class _DealerRegistrationScreenState extends State<DealerRegistrationScreen> {
  final FirestoreService _service = FirestoreService();
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();

  final List<GlobalKey<FormState>> _stepForms = List.generate(
    4,
    (_) => GlobalKey<FormState>(),
  );

  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _cnic = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _personalPhone = TextEditingController();

  final TextEditingController _companyName = TextEditingController();
  final TextEditingController _ntnNumber = TextEditingController();

  final TextEditingController _officeAddress = TextEditingController();
  final TextEditingController _area = TextEditingController();
  final TextEditingController _officePhone = TextEditingController();

  String _businessType = 'Residential Plots';
  String _yearsInBusiness = '1 - 3 Years';
  String _city = 'Gujranwala';

  bool _loading = true;
  bool _submitting = false;
  bool _acceptedTerms = false;

  int _currentStep = 0;
  Map<String, dynamic>? _existing;

  final Map<String, Map<String, dynamic>> _documents = {};
  final Set<String> _uploadingDocuments = <String>{};
  String? _profileImageUrl;
  bool _uploadingProfileImage = false;

  static const List<String> _businessTypes = [
    'Residential Plots',
    'Commercial Plots',
    'Residential & Commercial',
    'Farm Houses',
    'Apartments',
    'Property Consultancy',
  ];

  static const List<String> _experienceOptions = [
    'Less than 1 Year',
    '1 - 3 Years',
    '4 - 6 Years',
    '7 - 10 Years',
    '10+ Years',
  ];

  static const List<String> _cities = [
    'Gujranwala',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Sialkot',
    'Gujrat',
    'Multan',
    'Karachi',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullName.dispose();
    _cnic.dispose();
    _email.dispose();
    _personalPhone.dispose();
    _companyName.dispose();
    _ntnNumber.dispose();
    _officeAddress.dispose();
    _area.dispose();
    _officePhone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final applicant = await _service.getApplicant(uid);
      final applicantData =
          applicant.data() as Map<String, dynamic>? ?? <String, dynamic>{};

      _fullName.text = (applicantData['fullName'] ?? '').toString();
      _cnic.text = (applicantData['cnic'] ?? '').toString();
      _email.text = (applicantData['email'] ?? user?.email ?? '').toString();
      _personalPhone.text = (applicantData['phone'] ?? '').toString();

      final applicantCity = (applicantData['city'] ?? '').toString().trim();
      if (applicantCity.isNotEmpty && _cities.contains(applicantCity)) {
        _city = applicantCity;
      }

      final existing = await _service.getDealerRegistration(uid);

      if (mounted) {
        final existingData = existing?.data() as Map<String, dynamic>?;
        setState(() {
          _existing = existingData;
          _profileImageUrl =
              (existingData?['profileImageUrl'] ?? '').toString().trim().isEmpty
                  ? null
                  : existingData?['profileImageUrl'].toString();
        });
      }
    } catch (_) {
      // Keep the registration page usable even if optional prefill fails.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDocument(String key, String title) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('Please login again.');
      return;
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final extension = (file.extension ?? '').toLowerCase();
    final bytes = file.bytes;

    if (file.size <= 0) {
      _snack('$title file is empty.');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      _snack('$title must be 5MB or smaller.');
      return;
    }
    if (!const ['pdf', 'png', 'jpg', 'jpeg'].contains(extension)) {
      _snack('Use PDF, JPG or PNG only.');
      return;
    }
    if (file.name.trim().length < 3 ||
        file.name.contains(RegExp(r'[<>:"/\\|?*]'))) {
      _snack('Please choose a file with a valid name.');
      return;
    }
    if (bytes == null) {
      _snack('$title could not be read. Please select it again.');
      return;
    }

    setState(() => _uploadingDocuments.add(key));

    try {
      final uploadedUrl = await _storageService.uploadFile(
        bytes,
        'dealer_${uid}_${key}_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      final serial =
          'DLR-${DateTime.now().year}-${Random.secure().nextInt(900000) + 100000}';

      if (!mounted) return;
      setState(() {
        _documents[key] = {
          'documentKey': key,
          'documentTitle': title,
          'name': file.name,
          'type': extension,
          'size': file.size,
          'serial': serial,
          'url': uploadedUrl,
        };
      });
    } catch (_) {
      if (mounted) {
        _snack('$title upload failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingDocuments.remove(key));
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('Please login again.');
      return;
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final extension = (file.extension ?? '').toLowerCase();
    final bytes = file.bytes;

    if (!const ['png', 'jpg', 'jpeg'].contains(extension)) {
      _snack('Profile image must be JPG or PNG.');
      return;
    }
    if (file.size <= 0 || file.size > 2 * 1024 * 1024) {
      _snack('Profile image must be smaller than 2MB.');
      return;
    }
    if (bytes == null) {
      _snack('Profile image could not be read. Please select it again.');
      return;
    }

    final hadImage = _profileImageUrl != null && _profileImageUrl!.isNotEmpty;
    setState(() => _uploadingProfileImage = true);
    try {
      final url = await _storageService.uploadImage(
        bytes,
        'dealer_profile_${uid}_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      if (!mounted) return;
      setState(() => _profileImageUrl = url);
      _snack(hadImage ? 'Profile image updated.' : 'Profile image uploaded.');
    } catch (_) {
      if (mounted) _snack('Profile image upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploadingProfileImage = false);
    }
  }

  Future<void> _submit() async {
    if (_uploadingProfileImage || _uploadingDocuments.isNotEmpty) {
      _snack('Please wait for file uploads to finish.');
      return;
    }
    // Do not validate unmounted FormState objects here. On mobile only the
    // active registration step is mounted, so currentState is null for the
    // other steps. The old implementation treated that null as invalid and
    // blocked a fully completed registration. Validate the actual values
    // instead, then keep step-level Form validation for the Next buttons.
    final fieldError = _validateAllRegistrationValues();
    if (fieldError != null) {
      _snack(fieldError);
      return;
    }

    const requiredDocuments = [
      'cnic_front',
      'cnic_back',
      'business_card',
      'office_photo',
    ];

    if (!requiredDocuments.every(_documents.containsKey)) {
      _snack('Please select all four verification document records.');
      setState(() => _currentStep = 3);
      _scrollToProcess();
      return;
    }

    if (!_acceptedTerms) {
      _snack('Please accept the Terms & Conditions and Privacy Policy.');
      setState(() => _currentStep = 4);
      _scrollToProcess();
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('Please login again.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await _service.saveDealerRegistration(
        uid,
        {
          'fullName': _fullName.text.trim(),
          'cnic': _cnic.text.trim(),
          'cnicDigits': Validators.onlyDigits(_cnic.text),
          'email': _email.text.trim(),
          'phone': _personalPhone.text.trim(),
          'profileImageUrl': _profileImageUrl ?? '',
          'companyName': _companyName.text.trim(),
          'businessType': _businessType,
          'specialization': _businessType,
          'ntnNumber': _ntnNumber.text.trim(),
          'yearsInBusiness': _yearsInBusiness,
          'businessAddress': _officeAddress.text.trim(),
          'officeAddress': _officeAddress.text.trim(),
          'city': _city,
          'area': _area.text.trim(),
          'officePhone': _officePhone.text.trim(),
          'documents': _documents.values.toList(),
          'termsAccepted': true,
        },
      );

      final current = await _service.getDealerRegistration(uid);

      if (mounted) {
        setState(() {
          _existing = current?.data() as Map<String, dynamic>?;
        });
        _snack('Dealer registration submitted for DHS verification.');
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }


  String? _validateAllRegistrationValues() {
    final fullNameError = Validators.fullName(_fullName.text);
    if (fullNameError != null) {
      setState(() => _currentStep = 0);
      _scrollToProcess();
      return fullNameError;
    }

    final cnicError = Validators.cnic(_cnic.text);
    if (cnicError != null) {
      setState(() => _currentStep = 0);
      _scrollToProcess();
      return cnicError;
    }

    final phoneError = Validators.phone(_personalPhone.text);
    if (phoneError != null) {
      setState(() => _currentStep = 0);
      _scrollToProcess();
      return phoneError;
    }

    final emailError = Validators.email(_email.text);
    if (emailError != null) {
      setState(() => _currentStep = 0);
      _scrollToProcess();
      return emailError;
    }

    final companyError =
        Validators.companyName(_companyName.text);
    if (companyError != null) {
      setState(() => _currentStep = 1);
      _scrollToProcess();
      return companyError;
    }

    final ntnError = Validators.ntn(_ntnNumber.text);
    if (ntnError != null) {
      setState(() => _currentStep = 1);
      _scrollToProcess();
      return ntnError;
    }

    if (_businessType.trim().isEmpty || _yearsInBusiness.trim().isEmpty) {
      setState(() => _currentStep = 1);
      _scrollToProcess();
      return 'Please select business type and years in business.';
    }

    final officeError =
        Validators.address(_officeAddress.text, label: 'Office address');
    if (officeError != null) {
      setState(() => _currentStep = 2);
      _scrollToProcess();
      return officeError;
    }

    final areaError = Validators.area(_area.text);
    if (areaError != null) {
      setState(() => _currentStep = 2);
      _scrollToProcess();
      return areaError;
    }

    final officePhoneError = Validators.phone(_officePhone.text);
    if (officePhoneError != null) {
      setState(() => _currentStep = 2);
      _scrollToProcess();
      return officePhoneError;
    }

    if (_city.trim().isEmpty) {
      setState(() => _currentStep = 2);
      _scrollToProcess();
      return 'City is required.';
    }

    return null;
  }

  void _nextStep(int step) {
    if (_uploadingProfileImage || _uploadingDocuments.isNotEmpty) {
      _snack('Please wait for file uploads to finish.');
      return;
    }
    final formIndex = step.clamp(0, 3).toInt();

    if (step <= 3) {
      final valid = _stepForms[formIndex].currentState?.validate() ?? false;
      if (!valid) return;
    }

    if (step == 3) {
      const requiredDocuments = [
        'cnic_front',
        'cnic_back',
        'business_card',
        'office_photo',
      ];

      if (!requiredDocuments.every(_documents.containsKey)) {
        _snack('Please select all four verification document records.');
        return;
      }
    }

    setState(() => _currentStep = (step + 1).clamp(0, 4).toInt());
  }

  void _scrollToProcess() {
    Future.delayed(const Duration(milliseconds: 80), () async {
      if (!_scrollController.hasClients) return;
      await _scrollController.animateTo(
        210,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DhsResponsiveShell(
      currentRoute: AppConstants.dealerRegistrationRoute,
      mobileTitle: 'Dealer Registration',
      backgroundColor: const Color(0xFFF7F9FD),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
              ),
            )
          : SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: const _RegistrationHero(),
                        ),
                        SliverToBoxAdapter(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1240),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 22, 18, 0),
                                child: _existing != null
                                    ? _SubmittedState(
                                        data: _existing!,
                                        onDealers: () => Navigator.pushNamed(
                                          context,
                                          AppConstants.dealersRoute,
                                        ),
                                      )
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          Widget processColumn() => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  _ProcessTitle(),
                                                  const SizedBox(height: 18),
                                                  _RegistrationProcess(
                                                    currentStep: _currentStep,
                                                    onStepSelected: (step) {
                                                      setState(
                                                        () => _currentStep = step,
                                                      );
                                                    },
                                                    personalFormKey:
                                                        _stepForms[0],
                                                    businessFormKey:
                                                        _stepForms[1],
                                                    officeFormKey:
                                                        _stepForms[2],
                                                    documentsFormKey:
                                                        _stepForms[3],
                                                    fullName: _fullName,
                                                    cnic: _cnic,
                                                    phone: _personalPhone,
                                                    companyName: _companyName,
                                                    ntnNumber: _ntnNumber,
                                                    officeAddress:
                                                        _officeAddress,
                                                    area: _area,
                                                    officePhone: _officePhone,
                                                    businessType:
                                                        _businessType,
                                                    yearsInBusiness:
                                                        _yearsInBusiness,
                                                    city: _city,
                                                    businessTypes:
                                                        _businessTypes,
                                                    experienceOptions:
                                                        _experienceOptions,
                                                    cities: _cities,
                                                    documents: _documents,
                                                    profileImageUrl:
                                                        _profileImageUrl,
                                                    uploadingProfileImage:
                                                        _uploadingProfileImage,
                                                    acceptedTerms:
                                                        _acceptedTerms,
                                                    submitting: _submitting,
                                                    onBusinessTypeChanged:
                                                        (value) => setState(
                                                      () => _businessType = value,
                                                    ),
                                                    onExperienceChanged:
                                                        (value) => setState(
                                                      () =>
                                                          _yearsInBusiness = value,
                                                    ),
                                                    onCityChanged: (value) =>
                                                        setState(
                                                      () => _city = value,
                                                    ),
                                                    onPickProfileImage:
                                                        _pickProfileImage,
                                                    onPickDocument:
                                                        _pickDocument,
                                                    onTermsChanged: (value) =>
                                                        setState(
                                                      () =>
                                                          _acceptedTerms = value,
                                                    ),
                                                    onNext: _nextStep,
                                                    onEditStep: (step) =>
                                                        setState(
                                                      () => _currentStep = step,
                                                    ),
                                                    onSubmit: _submit,
                                                  ),
                                                ],
                                              );

                                          final sideColumn = Column(
                                            children: [
                                              const _BenefitsCard(),
                                              const SizedBox(height: 16),
                                              _AlreadyRegisteredStrip(
                                                onPressed: () =>
                                                    Navigator.pushNamed(
                                                  context,
                                                  AppConstants.dealersRoute,
                                                ),
                                              ),
                                            ],
                                          );

                                          if (constraints.maxWidth >= 980) {
                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: processColumn(),
                                                ),
                                                const SizedBox(width: 18),
                                                SizedBox(
                                                  width: 300,
                                                  child: sideColumn,
                                                ),
                                              ],
                                            );
                                          }

                                          return Column(
                                            children: [
                                              processColumn(),
                                              const SizedBox(height: 18),
                                              sideColumn,
                                            ],
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

}

class _RegistrationHero extends StatelessWidget {
  const _RegistrationHero();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 0 : 18,
        compact ? 0 : 14,
        compact ? 0 : 18,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 0 : 26),
        child: SizedBox(
          height: compact ? 255 : 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                compact
                    ? AppAssets.dealerRegistrationMobileBackground
                    : AppAssets.dealerRegistrationBackground,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: .74),
                      Colors.black.withValues(alpha: .44),
                      Colors.black.withValues(alpha: .10),
                    ],
                    stops: const [0.0, .50, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 28 : 34,
                  vertical: compact ? 26 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Become a',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontSize: compact ? 17 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Verified Dealer',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: compact ? 34 : 38,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Container(
                      width: 55,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD52E),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    const SizedBox(height: 13),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 610),
                      child: Text(
                        'Join our network of trusted and verified dealers. Help customers find their dream plots with confidence.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: .96),
                          fontSize: compact ? 14 : 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Register as a Dealer?',
            style: AppTextStyles.labelBold.copyWith(
              color: const Color(0xFF1F3DAF),
            ),
          ),
          const SizedBox(height: 18),
          const _BenefitItem(
            icon: Icons.verified_user_outlined,
            title: 'Build Trust',
            subtitle:
                'Get verified and build trust with thousands of customers',
          ),
          const _BenefitItem(
            icon: Icons.trending_up_rounded,
            title: 'Grow Business',
            subtitle: 'Access more leads and grow your business',
          ),
          const _BenefitItem(
            icon: Icons.star_border_rounded,
            title: 'Exclusive Benefits',
            subtitle: 'Get exclusive updates and promotions from DHS',
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF3156D8),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelBold),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.captionText.copyWith(
                    height: 1.45,
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlreadyRegisteredStrip extends StatelessWidget {
  const _AlreadyRegisteredStrip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Already have an account?',
                style: AppTextStyles.labelBold.copyWith(
                  color: const Color(0xFF1F3DAF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'If you’re already a registered dealer, open the verified dealer directory.',
                style: AppTextStyles.captionText,
              ),
            ],
          );

          final button = OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3156D8),
              side: const BorderSide(color: Color(0xFFB9C7F6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Go to Dealers'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: 12),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _ProcessTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dealer Registration Process',
          style: AppTextStyles.headingMedium.copyWith(
            color: const Color(0xFF1640B8),
            fontSize: compact ? 22 : 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD52E),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

class _RegistrationProcess extends StatelessWidget {
  const _RegistrationProcess({
    required this.currentStep,
    required this.onStepSelected,
    required this.personalFormKey,
    required this.businessFormKey,
    required this.officeFormKey,
    required this.documentsFormKey,
    required this.fullName,
    required this.cnic,
    required this.phone,
    required this.companyName,
    required this.ntnNumber,
    required this.officeAddress,
    required this.area,
    required this.officePhone,
    required this.businessType,
    required this.yearsInBusiness,
    required this.city,
    required this.businessTypes,
    required this.experienceOptions,
    required this.cities,
    required this.documents,
    required this.profileImageUrl,
    required this.uploadingProfileImage,
    required this.acceptedTerms,
    required this.submitting,
    required this.onBusinessTypeChanged,
    required this.onExperienceChanged,
    required this.onCityChanged,
    required this.onPickProfileImage,
    required this.onPickDocument,
    required this.onTermsChanged,
    required this.onNext,
    required this.onEditStep,
    required this.onSubmit,
  });

  final int currentStep;
  final ValueChanged<int> onStepSelected;

  final GlobalKey<FormState> personalFormKey;
  final GlobalKey<FormState> businessFormKey;
  final GlobalKey<FormState> officeFormKey;
  final GlobalKey<FormState> documentsFormKey;

  final TextEditingController fullName;
  final TextEditingController cnic;
  final TextEditingController phone;
  final TextEditingController companyName;
  final TextEditingController ntnNumber;
  final TextEditingController officeAddress;
  final TextEditingController area;
  final TextEditingController officePhone;

  final String businessType;
  final String yearsInBusiness;
  final String city;

  final List<String> businessTypes;
  final List<String> experienceOptions;
  final List<String> cities;

  final Map<String, Map<String, dynamic>> documents;
  final String? profileImageUrl;
  final bool uploadingProfileImage;
  final bool acceptedTerms;
  final bool submitting;

  final ValueChanged<String> onBusinessTypeChanged;
  final ValueChanged<String> onExperienceChanged;
  final ValueChanged<String> onCityChanged;
  final Future<void> Function() onPickProfileImage;
  final Future<void> Function(String key, String title) onPickDocument;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<int> onNext;
  final ValueChanged<int> onEditStep;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      _PersonalStep(
        formKey: personalFormKey,
        fullName: fullName,
        cnic: cnic,
        phone: phone,
        profileImageUrl: profileImageUrl,
        uploadingProfileImage: uploadingProfileImage,
        onPickProfileImage: onPickProfileImage,
        onNext: () => onNext(0),
      ),
      _BusinessStep(
        formKey: businessFormKey,
        companyName: companyName,
        ntnNumber: ntnNumber,
        businessType: businessType,
        yearsInBusiness: yearsInBusiness,
        businessTypes: businessTypes,
        experienceOptions: experienceOptions,
        onBusinessTypeChanged: onBusinessTypeChanged,
        onExperienceChanged: onExperienceChanged,
        onNext: () => onNext(1),
      ),
      _OfficeStep(
        formKey: officeFormKey,
        officeAddress: officeAddress,
        area: area,
        officePhone: officePhone,
        city: city,
        cities: cities,
        onCityChanged: onCityChanged,
        onNext: () => onNext(2),
      ),
      _DocumentsStep(
        formKey: documentsFormKey,
        documents: documents,
        onPickDocument: onPickDocument,
        onNext: () => onNext(3),
      ),
      _ReviewStep(
        acceptedTerms: acceptedTerms,
        submitting: submitting,
        onTermsChanged: onTermsChanged,
        onEditStep: onEditStep,
        onSubmit: onSubmit,
      ),
    ];

    const titles = [
      'Personal Information',
      'Business Information',
      'Office Information',
      'Documents Upload',
      'Review & Submit',
    ];
    const subtitles = [
      'Enter your personal details',
      'Enter your business details',
      'Enter your office details',
      'Upload required documents',
      'Review and submit application',
    ];

    return Column(
      children: [
        _MobileStepHeader(
          currentStep: currentStep,
          onStepSelected: onStepSelected,
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(currentStep),
            child: _StepCardShell(
              number: currentStep + 1,
              title: titles[currentStep],
              subtitle: subtitles[currentStep],
              selected: true,
              child: steps[currentStep],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCardShell extends StatelessWidget {
  const _StepCardShell({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
    this.selected = false,
  });

  final int number;
  final String title;
  final String subtitle;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? const Color(0xFF7A58EE)
              : const Color(0xFFE5EAF5),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A69C7).withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 42 : 48,
                height: compact ? 42 : 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF146FEF),
                      Color(0xFF7541E7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF644BEB).withValues(alpha: .24),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppTextStyles.labelBold.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: const Color(0xFF203169),
                        fontSize: compact ? 18 : 20,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF7A8398),
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 20 : 24),
          child,
        ],
      ),
    );
  }
}

class _MobileStepHeader extends StatelessWidget {
  const _MobileStepHeader({
    required this.currentStep,
    required this.onStepSelected,
  });

  final int currentStep;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(5, (index) {
          final selected = currentStep == index;
          final completed = currentStep > index;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => onStepSelected(index),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEDF1FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF6A50E9)
                        : const Color(0xFFE5EAF5),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: completed
                          ? const Color(0xFF1CB86D)
                          : selected
                              ? const Color(0xFF5D49E5)
                              : const Color(0xFFF0F2F7),
                      child: completed
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: AppTextStyles.captionText.copyWith(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF667085),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      const [
                        'Personal',
                        'Business',
                        'Office',
                        'Documents',
                        'Review',
                      ][index],
                      style: AppTextStyles.captionText.copyWith(
                        color: selected
                            ? const Color(0xFF3442A8)
                            : const Color(0xFF667085),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PersonalStep extends StatelessWidget {
  const _PersonalStep({
    required this.formKey,
    required this.fullName,
    required this.cnic,
    required this.phone,
    required this.profileImageUrl,
    required this.uploadingProfileImage,
    required this.onPickProfileImage,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullName;
  final TextEditingController cnic;
  final TextEditingController phone;
  final String? profileImageUrl;
  final bool uploadingProfileImage;
  final Future<void> Function() onPickProfileImage;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;

          final fields = Column(
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CompactTextField(
                        label: 'Full Name',
                        hint: 'Enter full name',
                        controller: fullName,
                        validator: Validators.fullName,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _CompactTextField(
                        label: 'CNIC Number',
                        hint: 'xxxxx-xxxxxxx-x',
                        controller: cnic,
                        inputFormatters: [CnicInputFormatter()],
                        keyboardType: TextInputType.number,
                        validator: Validators.cnic,
                      ),
                    ),
                  ],
                )
              else ...[
                _CompactTextField(
                  label: 'Full Name',
                  hint: 'Enter full name',
                  controller: fullName,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 11),
                _CompactTextField(
                  label: 'CNIC Number',
                  hint: 'xxxxx-xxxxxxx-x',
                  controller: cnic,
                  inputFormatters: [CnicInputFormatter()],
                  keyboardType: TextInputType.number,
                  validator: Validators.cnic,
                ),
              ],
              const SizedBox(height: 11),
              _CompactTextField(
                label: 'Phone Number',
                hint: '03xx-xxxxxxx',
                controller: phone,
                inputFormatters: [PakistaniPhoneFormatter()],
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
            ],
          );

          if (!wide) {
            return Column(
              children: [
                _ProfileImagePicker(
                  imageUrl: profileImageUrl,
                  uploading: uploadingProfileImage,
                  onTap: onPickProfileImage,
                ),
                const SizedBox(height: 16),
                fields,
                const SizedBox(height: 18),
                _StepButton(
                  text: 'Next',
                  onPressed: onNext,
                  blue: true,
                ),
              ],
            );
          }

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 170,
                    child: _ProfileImagePicker(
                      imageUrl: profileImageUrl,
                      uploading: uploadingProfileImage,
                      onTap: onPickProfileImage,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: fields),
                ],
              ),
              const SizedBox(height: 20),
              _StepButton(
                text: 'Next',
                onPressed: onNext,
                blue: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileImagePicker extends StatelessWidget {
  const _ProfileImagePicker({
    required this.imageUrl,
    required this.uploading,
    required this.onTap,
  });

  final String? imageUrl;
  final bool uploading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: uploading ? null : onTap,
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipOval(
                    child: hasImage
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF0F3FB),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 62,
                                color: Color(0xFFB8C1D9),
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF0F3FB),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 62,
                              color: Color(0xFFB8C1D9),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3156E8),
                      shape: BoxShape.circle,
                    ),
                    child: uploading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            hasImage
                                ? Icons.edit_rounded
                                : Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 19,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasImage ? 'Change Profile Image' : 'Upload Profile Image',
          textAlign: TextAlign.center,
          style: AppTextStyles.captionText.copyWith(
            color: const Color(0xFF3156D8),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'JPG, PNG (Max 2MB)',
          textAlign: TextAlign.center,
          style: AppTextStyles.captionText.copyWith(fontSize: 9.5),
        ),
      ],
    );
  }
}

class _BusinessStep extends StatelessWidget {
  const _BusinessStep({
    required this.formKey,
    required this.companyName,
    required this.ntnNumber,
    required this.businessType,
    required this.yearsInBusiness,
    required this.businessTypes,
    required this.experienceOptions,
    required this.onBusinessTypeChanged,
    required this.onExperienceChanged,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController companyName;
  final TextEditingController ntnNumber;
  final String businessType;
  final String yearsInBusiness;
  final List<String> businessTypes;
  final List<String> experienceOptions;
  final ValueChanged<String> onBusinessTypeChanged;
  final ValueChanged<String> onExperienceChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final itemWidth = wide
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;

          return Column(
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 11,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _CompactTextField(
                      label: 'Company Name',
                      hint: 'Enter company name',
                      controller: companyName,
                      validator: Validators.companyName,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactDropdown(
                      label: 'Business Type',
                      value: businessType,
                      items: businessTypes,
                      onChanged: onBusinessTypeChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactTextField(
                      label: 'NTN Number',
                      hint: '1234567-8',
                      controller: ntnNumber,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                        LengthLimitingTextInputFormatter(9),
                      ],
                      validator: Validators.ntn,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactDropdown(
                      label: 'Years in Business',
                      value: yearsInBusiness,
                      items: experienceOptions,
                      onChanged: onExperienceChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _StepButton(
                text: 'Next',
                onPressed: onNext,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OfficeStep extends StatelessWidget {
  const _OfficeStep({
    required this.formKey,
    required this.officeAddress,
    required this.area,
    required this.officePhone,
    required this.city,
    required this.cities,
    required this.onCityChanged,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController officeAddress;
  final TextEditingController area;
  final TextEditingController officePhone;
  final String city;
  final List<String> cities;
  final ValueChanged<String> onCityChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final itemWidth = wide
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;

          return Column(
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 11,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _CompactTextField(
                      label: 'Office Address',
                      hint: 'Enter office address',
                      controller: officeAddress,
                      validator: (value) => Validators.address(
                        value,
                        label: 'Office address',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactDropdown(
                      label: 'City',
                      value: city,
                      items: cities,
                      onChanged: onCityChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactTextField(
                      label: 'Area',
                      hint: 'Enter area',
                      controller: area,
                      validator: Validators.area,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactTextField(
                      label: 'Phone Number',
                      hint: '03xx-xxxxxxx',
                      controller: officePhone,
                      inputFormatters: [PakistaniPhoneFormatter()],
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _StepButton(
                text: 'Next',
                onPressed: onNext,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentsStep extends StatelessWidget {
  const _DocumentsStep({
    required this.formKey,
    required this.documents,
    required this.onPickDocument,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, Map<String, dynamic>> documents;
  final Future<void> Function(String key, String title) onPickDocument;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final itemWidth = wide
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          return Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _DocumentUploadRow(
                      title: 'CNIC (Front)',
                      data: documents['cnic_front'],
                      onTap: () => onPickDocument('cnic_front', 'CNIC Front'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _DocumentUploadRow(
                      title: 'CNIC (Back)',
                      data: documents['cnic_back'],
                      onTap: () => onPickDocument('cnic_back', 'CNIC Back'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _DocumentUploadRow(
                      title: 'Business Card',
                      data: documents['business_card'],
                      onTap: () =>
                          onPickDocument('business_card', 'Business Card'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _DocumentUploadRow(
                      title: 'Office Photo',
                      data: documents['office_photo'],
                      onTap: () =>
                          onPickDocument('office_photo', 'Office Photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _StepButton(
                text: 'Next',
                onPressed: onNext,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentUploadRow extends StatelessWidget {
  const _DocumentUploadRow({
    required this.title,
    required this.data,
    required this.onTap,
  });

  final String title;
  final Map<String, dynamic>? data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = data != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF2F4FF)
              : const Color(0xFFF9FAFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFA8B5F9)
                : const Color(0xFFE5E9F2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                selected
                    ? Icons.task_alt_rounded
                    : Icons.image_outlined,
                color: selected
                    ? const Color(0xFF1DB16D)
                    : const Color(0xFF3156D8),
                size: 19,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelBold.copyWith(
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected
                        ? (data!['name'] ?? 'Selected').toString()
                        : 'Upload image',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionText.copyWith(
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                selected
                    ? Icons.edit_outlined
                    : Icons.cloud_upload_outlined,
                color: const Color(0xFF3156D8),
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.acceptedTerms,
    required this.submitting,
    required this.onTermsChanged,
    required this.onEditStep,
    required this.onSubmit,
  });

  final bool acceptedTerms;
  final bool submitting;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<int> onEditStep;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReviewRow(
          title: 'Personal Information',
          onEdit: () => onEditStep(0),
        ),
        _ReviewRow(
          title: 'Business Information',
          onEdit: () => onEditStep(1),
        ),
        _ReviewRow(
          title: 'Office Information',
          onEdit: () => onEditStep(2),
        ),
        _ReviewRow(
          title: 'Documents',
          onEdit: () => onEditStep(3),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => onTermsChanged(!acceptedTerms),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: acceptedTerms,
                  onChanged: (value) =>
                      onTermsChanged(value ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: AppTextStyles.captionText.copyWith(
                              color: const Color(0xFF3156D8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyles.captionText.copyWith(
                              color: const Color(0xFF3156D8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      style: AppTextStyles.captionText.copyWith(
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: submitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16AD64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Application'),
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.title,
    required this.onEdit,
  });

  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelBold.copyWith(fontSize: 10.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete',
                  style: AppTextStyles.captionText.copyWith(
                    color: const Color(0xFF16AD64),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF3156D8),
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTextField extends StatelessWidget {
  const _CompactTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionText.copyWith(
            color: const Color(0xFF2D3C68),
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF202A44),
            fontSize: 11,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.captionText.copyWith(
              fontSize: 9.5,
              color: const Color(0xFFA0A8BB),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFDCE2EF),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF5E4DE8),
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.errorRed,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  const _CompactDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionText.copyWith(
            color: const Color(0xFF2D3C68),
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFDCE2EF),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF202A44),
                fontSize: 10.5,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.text,
    required this.onPressed,
    this.blue = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool blue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: blue
              ? const LinearGradient(
                  colors: [
                    Color(0xFF126DEB),
                    Color(0xFF2461E5),
                  ],
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFF5843E8),
                    Color(0xFF7540EA),
                  ],
                ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE3E8F3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5267B4).withValues(alpha: .07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SubmittedState extends StatelessWidget {
  const _SubmittedState({
    required this.data,
    required this.onDealers,
  });

  final Map<String, dynamic> data;
  final VoidCallback onDealers;

  @override
  Widget build(BuildContext context) {
    final status =
        (data['verificationStatus'] ?? 'pending').toString().toLowerCase();

    final isVerified = status == 'verified' || status == 'approved';
    final isRejected = status == 'rejected';

    final statusColor = isVerified
        ? const Color(0xFF16AD64)
        : isRejected
            ? AppColors.errorRed
            : const Color(0xFFF59E0B);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _WhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVerified
                      ? Icons.verified_rounded
                      : isRejected
                          ? Icons.cancel_outlined
                          : Icons.hourglass_top_rounded,
                  color: statusColor,
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.labelBold.copyWith(
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isVerified
                    ? 'Dealer Registration Verified'
                    : isRejected
                        ? 'Dealer Registration Rejected'
                        : 'Registration Submitted',
                style: AppTextStyles.headingMedium.copyWith(
                  color: const Color(0xFF1640B8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isVerified
                    ? 'Your dealer profile has been verified by DHS administration.'
                    : isRejected
                        ? 'Your dealer registration was not approved. Please contact DHS support for details.'
                        : 'Your dealer registration has been submitted successfully and is under review by the DHS administration. We will notify you once the review is completed.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDealers,
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('Open Verified Dealers'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
