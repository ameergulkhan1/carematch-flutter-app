import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountryData {
  final String name;
  final String code;
  final String dialCode;
  final int minLength;
  final int maxLength;
  final String flag;

  const CountryData({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.minLength,
    required this.maxLength,
    required this.flag,
  });
}

class PhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final void Function(CountryData)? onCountryChanged;
  final String? initialCountryCode;

  const PhoneNumberInput({
    super.key,
    required this.controller,
    this.validator,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.onCountryChanged,
    this.initialCountryCode,
  });

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  late CountryData _selectedCountry;

  // Comprehensive list of countries with phone number rules
  static const List<CountryData> countries = [
    // North America
    CountryData(name: 'United States', code: 'US', dialCode: '+1', minLength: 10, maxLength: 10, flag: '🇺🇸'),
    CountryData(name: 'Canada', code: 'CA', dialCode: '+1', minLength: 10, maxLength: 10, flag: '🇨🇦'),
    CountryData(name: 'Mexico', code: 'MX', dialCode: '+52', minLength: 10, maxLength: 10, flag: '🇲🇽'),
    
    // Europe
    CountryData(name: 'United Kingdom', code: 'GB', dialCode: '+44', minLength: 10, maxLength: 10, flag: '🇬🇧'),
    CountryData(name: 'Germany', code: 'DE', dialCode: '+49', minLength: 10, maxLength: 11, flag: '🇩🇪'),
    CountryData(name: 'France', code: 'FR', dialCode: '+33', minLength: 9, maxLength: 9, flag: '🇫🇷'),
    CountryData(name: 'Italy', code: 'IT', dialCode: '+39', minLength: 9, maxLength: 10, flag: '🇮🇹'),
    CountryData(name: 'Spain', code: 'ES', dialCode: '+34', minLength: 9, maxLength: 9, flag: '🇪🇸'),
    CountryData(name: 'Netherlands', code: 'NL', dialCode: '+31', minLength: 9, maxLength: 9, flag: '🇳🇱'),
    CountryData(name: 'Belgium', code: 'BE', dialCode: '+32', minLength: 9, maxLength: 9, flag: '🇧🇪'),
    CountryData(name: 'Switzerland', code: 'CH', dialCode: '+41', minLength: 9, maxLength: 9, flag: '🇨🇭'),
    CountryData(name: 'Sweden', code: 'SE', dialCode: '+46', minLength: 9, maxLength: 10, flag: '🇸🇪'),
    CountryData(name: 'Norway', code: 'NO', dialCode: '+47', minLength: 8, maxLength: 8, flag: '🇳🇴'),
    CountryData(name: 'Denmark', code: 'DK', dialCode: '+45', minLength: 8, maxLength: 8, flag: '🇩🇰'),
    CountryData(name: 'Finland', code: 'FI', dialCode: '+358', minLength: 9, maxLength: 10, flag: '🇫🇮'),
    CountryData(name: 'Poland', code: 'PL', dialCode: '+48', minLength: 9, maxLength: 9, flag: '🇵🇱'),
    CountryData(name: 'Ireland', code: 'IE', dialCode: '+353', minLength: 9, maxLength: 9, flag: '🇮🇪'),
    CountryData(name: 'Portugal', code: 'PT', dialCode: '+351', minLength: 9, maxLength: 9, flag: '🇵🇹'),
    CountryData(name: 'Austria', code: 'AT', dialCode: '+43', minLength: 10, maxLength: 11, flag: '🇦🇹'),
    CountryData(name: 'Czech Republic', code: 'CZ', dialCode: '+420', minLength: 9, maxLength: 9, flag: '🇨🇿'),
    
    // Asia
    CountryData(name: 'India', code: 'IN', dialCode: '+91', minLength: 10, maxLength: 10, flag: '🇮🇳'),
    CountryData(name: 'Pakistan', code: 'PK', dialCode: '+92', minLength: 10, maxLength: 10, flag: '🇵🇰'),
    CountryData(name: 'Bangladesh', code: 'BD', dialCode: '+880', minLength: 10, maxLength: 10, flag: '🇧🇩'),
    CountryData(name: 'China', code: 'CN', dialCode: '+86', minLength: 11, maxLength: 11, flag: '🇨🇳'),
    CountryData(name: 'Japan', code: 'JP', dialCode: '+81', minLength: 10, maxLength: 10, flag: '🇯🇵'),
    CountryData(name: 'South Korea', code: 'KR', dialCode: '+82', minLength: 9, maxLength: 10, flag: '🇰🇷'),
    CountryData(name: 'Thailand', code: 'TH', dialCode: '+66', minLength: 9, maxLength: 9, flag: '🇹🇭'),
    CountryData(name: 'Vietnam', code: 'VN', dialCode: '+84', minLength: 9, maxLength: 10, flag: '🇻🇳'),
    CountryData(name: 'Philippines', code: 'PH', dialCode: '+63', minLength: 10, maxLength: 10, flag: '🇵🇭'),
    CountryData(name: 'Indonesia', code: 'ID', dialCode: '+62', minLength: 9, maxLength: 11, flag: '🇮🇩'),
    CountryData(name: 'Malaysia', code: 'MY', dialCode: '+60', minLength: 9, maxLength: 10, flag: '🇲🇾'),
    CountryData(name: 'Singapore', code: 'SG', dialCode: '+65', minLength: 8, maxLength: 8, flag: '🇸🇬'),
    CountryData(name: 'Hong Kong', code: 'HK', dialCode: '+852', minLength: 8, maxLength: 8, flag: '🇭🇰'),
    CountryData(name: 'Taiwan', code: 'TW', dialCode: '+886', minLength: 9, maxLength: 9, flag: '🇹🇼'),
    CountryData(name: 'Sri Lanka', code: 'LK', dialCode: '+94', minLength: 9, maxLength: 9, flag: '🇱🇰'),
    CountryData(name: 'Nepal', code: 'NP', dialCode: '+977', minLength: 10, maxLength: 10, flag: '🇳🇵'),
    CountryData(name: 'Afghanistan', code: 'AF', dialCode: '+93', minLength: 9, maxLength: 9, flag: '🇦🇫'),
    
    // Middle East
    CountryData(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', minLength: 9, maxLength: 9, flag: '🇸🇦'),
    CountryData(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', minLength: 9, maxLength: 9, flag: '🇦🇪'),
    CountryData(name: 'Qatar', code: 'QA', dialCode: '+974', minLength: 8, maxLength: 8, flag: '🇶🇦'),
    CountryData(name: 'Kuwait', code: 'KW', dialCode: '+965', minLength: 8, maxLength: 8, flag: '🇰🇼'),
    CountryData(name: 'Bahrain', code: 'BH', dialCode: '+973', minLength: 8, maxLength: 8, flag: '🇧🇭'),
    CountryData(name: 'Oman', code: 'OM', dialCode: '+968', minLength: 8, maxLength: 8, flag: '🇴🇲'),
    CountryData(name: 'Jordan', code: 'JO', dialCode: '+962', minLength: 9, maxLength: 9, flag: '🇯🇴'),
    CountryData(name: 'Lebanon', code: 'LB', dialCode: '+961', minLength: 7, maxLength: 8, flag: '🇱🇧'),
    CountryData(name: 'Israel', code: 'IL', dialCode: '+972', minLength: 9, maxLength: 9, flag: '🇮🇱'),
    CountryData(name: 'Turkey', code: 'TR', dialCode: '+90', minLength: 10, maxLength: 10, flag: '🇹🇷'),
    CountryData(name: 'Iran', code: 'IR', dialCode: '+98', minLength: 10, maxLength: 10, flag: '🇮🇷'),
    CountryData(name: 'Iraq', code: 'IQ', dialCode: '+964', minLength: 10, maxLength: 10, flag: '🇮🇶'),
    
    // Africa
    CountryData(name: 'South Africa', code: 'ZA', dialCode: '+27', minLength: 9, maxLength: 9, flag: '🇿🇦'),
    CountryData(name: 'Nigeria', code: 'NG', dialCode: '+234', minLength: 10, maxLength: 10, flag: '🇳🇬'),
    CountryData(name: 'Kenya', code: 'KE', dialCode: '+254', minLength: 9, maxLength: 10, flag: '🇰🇪'),
    CountryData(name: 'Ghana', code: 'GH', dialCode: '+233', minLength: 9, maxLength: 9, flag: '🇬🇭'),
    CountryData(name: 'Egypt', code: 'EG', dialCode: '+20', minLength: 10, maxLength: 10, flag: '🇪🇬'),
    CountryData(name: 'Morocco', code: 'MA', dialCode: '+212', minLength: 9, maxLength: 9, flag: '🇲🇦'),
    CountryData(name: 'Ethiopia', code: 'ET', dialCode: '+251', minLength: 9, maxLength: 9, flag: '🇪🇹'),
    CountryData(name: 'Tanzania', code: 'TZ', dialCode: '+255', minLength: 9, maxLength: 9, flag: '🇹🇿'),
    CountryData(name: 'Uganda', code: 'UG', dialCode: '+256', minLength: 9, maxLength: 9, flag: '🇺🇬'),
    CountryData(name: 'Algeria', code: 'DZ', dialCode: '+213', minLength: 9, maxLength: 9, flag: '🇩🇿'),
    
    // South America
    CountryData(name: 'Brazil', code: 'BR', dialCode: '+55', minLength: 10, maxLength: 11, flag: '🇧🇷'),
    CountryData(name: 'Argentina', code: 'AR', dialCode: '+54', minLength: 10, maxLength: 11, flag: '🇦🇷'),
    CountryData(name: 'Colombia', code: 'CO', dialCode: '+57', minLength: 10, maxLength: 10, flag: '🇨🇴'),
    CountryData(name: 'Chile', code: 'CL', dialCode: '+56', minLength: 9, maxLength: 9, flag: '🇨🇱'),
    CountryData(name: 'Peru', code: 'PE', dialCode: '+51', minLength: 9, maxLength: 9, flag: '🇵🇪'),
    CountryData(name: 'Venezuela', code: 'VE', dialCode: '+58', minLength: 10, maxLength: 10, flag: '🇻🇪'),
    CountryData(name: 'Ecuador', code: 'EC', dialCode: '+593', minLength: 9, maxLength: 9, flag: '🇪🇨'),
    CountryData(name: 'Uruguay', code: 'UY', dialCode: '+598', minLength: 8, maxLength: 8, flag: '🇺🇾'),
    
    // Oceania
    CountryData(name: 'Australia', code: 'AU', dialCode: '+61', minLength: 9, maxLength: 9, flag: '🇦🇺'),
    CountryData(name: 'New Zealand', code: 'NZ', dialCode: '+64', minLength: 9, maxLength: 10, flag: '🇳🇿'),
    
    // Caribbean
    CountryData(name: 'Jamaica', code: 'JM', dialCode: '+1-876', minLength: 10, maxLength: 10, flag: '🇯🇲'),
    CountryData(name: 'Trinidad and Tobago', code: 'TT', dialCode: '+1-868', minLength: 10, maxLength: 10, flag: '🇹🇹'),
    CountryData(name: 'Dominican Republic', code: 'DO', dialCode: '+1-809', minLength: 10, maxLength: 10, flag: '🇩🇴'),
    
    // Central America
    CountryData(name: 'Guatemala', code: 'GT', dialCode: '+502', minLength: 8, maxLength: 8, flag: '🇬🇹'),
    CountryData(name: 'Costa Rica', code: 'CR', dialCode: '+506', minLength: 8, maxLength: 8, flag: '🇨🇷'),
    CountryData(name: 'Panama', code: 'PA', dialCode: '+507', minLength: 8, maxLength: 8, flag: '🇵🇦'),
  ];

  @override
  void initState() {
    super.initState();
    // Find initial country or default to US
    _selectedCountry = countries.firstWhere(
      (c) => c.code == (widget.initialCountryCode ?? 'US'),
      orElse: () => countries[0],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Select Country',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  final isSelected = country.code == _selectedCountry.code;
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country.dialCode,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check, color: Colors.green),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() => _selectedCountry = country);
                      widget.onCountryChanged?.call(country);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < _selectedCountry.minLength) {
      return 'Phone number must be at least ${_selectedCountry.minLength} digits for ${_selectedCountry.name}';
    }
    
    if (digitsOnly.length > _selectedCountry.maxLength) {
      return 'Phone number must not exceed ${_selectedCountry.maxLength} digits for ${_selectedCountry.name}';
    }

    return widget.validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
      ],
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Phone Number',
        hintText: widget.hintText ?? 'Enter phone number',
        prefixIcon: InkWell(
          onTap: widget.enabled ? _showCountryPicker : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedCountry.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedCountry.dialCode,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6B4CE6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: widget.enabled ? () => widget.controller.clear() : null,
              )
            : null,
      ),
      validator: _validatePhoneNumber,
      onChanged: (_) => setState(() {}),
    );
  }

  // Utility methods reserved for future use
  /*
  static String getFullPhoneNumber(String phoneNumber, CountryData country) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return '${country.dialCode} $digitsOnly';
  }

  static Map<String, String> parsePhoneNumber(String fullPhoneNumber) {
    for (final country in countries) {
      if (fullPhoneNumber.startsWith(country.dialCode)) {
        return {
          'countryCode': country.code,
          'dialCode': country.dialCode,
          'phoneNumber': fullPhoneNumber.replaceFirst(country.dialCode, '').trim(),
        };
      }
    }
    return {
      'countryCode': 'US',
      'dialCode': '+1',
      'phoneNumber': fullPhoneNumber,
    };
  }
  */
}
