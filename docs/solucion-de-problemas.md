# Solución de problemas

## Los atajos dejaron de funcionar en Mac (Secure Input)

Algunas apps (gestores de contraseñas, terminales, formularios de contraseña) activan «Secure Input»: macOS bloquea entonces que otras apps lean el teclado, incluido el atajo de Impulso Talker.

1. Cierra la app que tiene un campo de contraseña abierto o pulsa fuera del campo.
2. Si sigue sin responder, cierra sesión y vuelve a entrar, o reinicia el Mac.
3. Puedes ver cuál app lo mantiene activo con `ioreg -l -w 0 | grep SecureInput` en la Terminal.

## El atajo no responde después de actualizar o reinstalar (Mac)

Como la app no tiene firma de desarrollador, cada versión nueva cambia su «huella» y macOS olvida los permisos aunque sigan marcados.

1. Cierra Impulso Talker.
2. En la Terminal:

   ```
   tccutil reset Accessibility cl.agenciaimpulsa.talker
   tccutil reset Microphone cl.agenciaimpulsa.talker
   ```

3. Ábrela de nuevo y acepta Micrófono y Accesibilidad.

## Linux

Impulso Talker está pensado para Mac y Windows. En Linux puede compilarse (`bun run tauri build`), pero no está probado: los atajos globales y el pegado dependen del entorno gráfico (X11 o Wayland) y de tener `wtype` o `xdotool` instalados.

## Hablo y no aparece nada

- Revisa que el micrófono correcto esté elegido en _General → Sonido_.
- Revisa el permiso de Micrófono (Mac: _Ajustes del Sistema → Privacidad y seguridad → Micrófono_).
- Si el modelo sigue descargándose, espera a que termine (abajo a la izquierda se ve el estado).

## Transcribe pero no escribe el texto

Falta el permiso de **Accesibilidad** (Mac). Concédelo y reinicia la app.
