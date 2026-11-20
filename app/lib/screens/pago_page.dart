import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';
import '../models/tienda_model.dart';
import '../services/tienda_service.dart';
import '../utils/formatos.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

/// Proceso de pago en línea (pasarela simulada).
/// La app valida el formato y la API vuelve a validar todo antes de cobrar.
class PagoPage extends StatefulWidget {
  final double total;
  final int piezas;

  const PagoPage({super.key, required this.total, required this.piezas});

  @override
  State<PagoPage> createState() => _PagoPageState();
}

class _PagoPageState extends State<PagoPage> {
  final _formKey = GlobalKey<FormState>();
  final _titular = TextEditingController();
  final _numero = TextEditingController();
  final _expiracion = TextEditingController();
  final _cvv = TextEditingController();
  final _servicio = TiendaService();

  bool _pagando = false;
  String? _error;
  PedidoModel? _pedido;

  @override
  void dispose() {
    _titular.dispose();
    _numero.dispose();
    _expiracion.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _pagar() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _pagando = true);
    try {
      final pedido = await _servicio.pagar(
        titular: _titular.text,
        numero: _numero.text,
        expiracion: _expiracion.text,
        cvv: _cvv.text,
      );
      if (mounted) setState(() => _pedido = pedido);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _pagando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedido = _pedido;
    return PopScope(
      canPop: !_pagando,
      child: Scaffold(
        appBar: AppBar(title: Text(pedido == null ? 'Pago' : 'Pago aprobado')),
        body: pedido == null ? _formulario() : _confirmacion(pedido),
      ),
    );
  }

  Widget _formulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.azul.withValues(alpha: 0.08),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Total a pagar (${widget.piezas} piezas)'),
                    const Spacer(),
                    Text(
                      formatoPrecio(widget.total),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.marino),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Datos de la tarjeta', style: AppTheme.titulo(size: 20)),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _titular,
              label: 'Nombre del titular',
              prefixIcon: Icons.person,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().length < 3) ? 'Escribe el nombre como aparece en la tarjeta' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _numero,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, _FormatoTarjeta()],
              decoration: AppTheme.campo('Número de tarjeta', icono: Icons.credit_card),
              validator: (v) => TiendaService.luhnValido(v ?? '') ? null : 'Número de tarjeta no válido',
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiracion,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, _FormatoExpiracion()],
                    decoration: AppTheme.campo('MM/AA', icono: Icons.calendar_month),
                    validator: TiendaService.validarExpiracion,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: AppTheme.campo('CVV', icono: Icons.lock_outline).copyWith(counterText: ''),
                    validator: (v) => RegExp(r'^\d{3,4}$').hasMatch(v ?? '') ? null : 'CVV no válido',
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.rojo),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.rojo))),
                ],
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'PAGAR ${formatoPrecio(widget.total)}',
              cargando: _pagando,
              onPressed: _pagar,
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 18, color: Colors.grey),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pago simulado para la práctica. Solo se guardan la marca y los últimos 4 dígitos. '
                    'Tarjeta de prueba: 4242 4242 4242 4242.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmacion(PedidoModel pedido) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 12),
        Text('¡Gracias por tu compra!', textAlign: TextAlign.center, style: AppTheme.titulo(size: 24)),
        const SizedBox(height: 6),
        Text(
          'Folio ${pedido.referencia}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.azul),
        ),
        Text(
          '${pedido.marca} terminación ${pedido.ultimos4} · ${Formatos.fecha(pedido.fecha)} ${Formatos.hora(pedido.fecha)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...pedido.detalles.map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text('${d.cantidad} × ${d.nombre}')),
                          Text(formatoPrecio(d.precioUnit * d.cantidad)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      formatoPrecio(pedido.total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.marino),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'VOLVER A LA TIENDA',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// 4242424242424242 → 4242 4242 4242 4242
class _FormatoTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitos = newValue.text.length > 19 ? newValue.text.substring(0, 19) : newValue.text;
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitos[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}

/// 1229 → 12/29
class _FormatoExpiracion extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitos = newValue.text.length > 4 ? newValue.text.substring(0, 4) : newValue.text;
    final texto = digitos.length > 2 ? '${digitos.substring(0, 2)}/${digitos.substring(2)}' : digitos;
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
