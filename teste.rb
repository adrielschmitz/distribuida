require_relative 'vendor/bundle/gems/tty-spinner-0.9.0/lib/tty-spinner'

spinner = TTY::Spinner.new('[:spinner] Enviando Mensagem ...')
20.times do
  spinner.spin
  sleep(0.1)
end

spinner.success('(Mensagem enviada com sucesso!)')
spinner.error('(error)')
