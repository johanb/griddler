require 'spec_helper'

describe Griddler::Adapters::MandrillAdapter, '.normalize_params' do
  it 'normalizes parameters' do
    params = default_params

    normalized_params = Griddler::Adapters::MandrillAdapter.normalize_params(params)
    normalized_params.each do |params|
      params[:to].should eq ['The Token <token@reply.example.com>']
      params[:from].should eq 'hernan@example.com'
      params[:subject].should eq 'hello'
      params[:text].should include('Dear bob')
      params[:html].should include('<p>Dear bob</p>')
      params[:raw_body].should include('Test')
      params[:charsets] = ActiveSupport::JSON.encode({'html' => 'UTF-8', 'text' => 'UTF-8'})
    end
  end

  it 'passes the received array of files' do
    params = params_with_attachments

    normalized_params = Griddler::Adapters::MandrillAdapter.normalize_params(params)

    first, second = *normalized_params[0][:attachments]

    first.original_filename.should eq('photo1.jpg')
    first.size.should eq(upload_1_params[:length])

    second.original_filename.should eq('photo2.jpg')
    second.size.should eq(upload_2_params[:length])
  end

  it 'has no attachments' do
    params = default_params

    normalized_params = Griddler::Adapters::MandrillAdapter.normalize_params(params)

    normalized_params[0][:attachments].should be_empty
  end

  def default_params
    mandrill_events (params_hash*2).to_json
  end

  def params_hash
    [{
      event: "inbound",
      ts: 1364601140,
      msg:
        {
          raw_msg: RAW_MSG,
          headers: {},
          text: text_body,
          html: text_html,
          from_email: "hernan@example.com",
          from_name: "Hernan Example",
          to: [["token@reply.example.com", "The Token"]],
          subject: "hello",
          spam_report: {
            score: -0.8,
            matched_rules: "..."
            },
          dkim: {signed: true, valid: true},
          spf: {result: "pass", detail: "sender SPF authorized"},
          email: "token@reply.example.com",
          tags: [],
          sender: nil
        }
    }]
  end

  def params_with_attachments
    params = params_hash
    params[0][:msg][:attachments] = {
      'photo1.jpg' => upload_1_params,
      'photo2.jpg' => upload_2_params
    }
    mandrill_events params.to_json
  end

  def mandrill_events(json)
    { mandrill_events: json }
  end

  def text_body
    <<-EOS.strip_heredoc.strip
      Dear bob

      Reply ABOVE THIS LINE

      hey sup
    EOS
  end

  def text_html
    <<-EOS.strip_heredoc.strip
      <p>Dear bob</p>

      Reply ABOVE THIS LINE

      hey sup
    EOS
  end

  def cwd
    File.expand_path File.dirname(__FILE__)
  end

  def upload_1_params
    @upload_1_params ||= begin
      file = File.new("#{cwd}/../../../spec/fixtures/photo1.jpg")
      size = file.size
      {
        name: 'photo1.jpg',
        content: Base64.encode64(file.read),
        type: 'image/jpeg',
        length: file.size
      }
    end
  end

  def upload_2_params
    @upload_2_params ||= begin
      file = File.new("#{cwd}/../../../spec/fixtures/photo2.jpg")
      size = file.size
      {
        name: 'photo2.jpg',
        content: Base64.encode64(file.read),
        type: 'image/jpeg',
        length: file.size
      }
    end
  end

  def upload_1
    @upload_1 ||= ActionDispatch::Http::UploadedFile.new({
      filename: 'photo1.jpg',
      type: 'image/jpeg',
      tempfile: File.new("#{cwd}/../../../spec/fixtures/photo1.jpg")
    })
  end

  def upload_2
    @upload_2 ||= ActionDispatch::Http::UploadedFile.new({
      filename: 'photo2.jpg',
      type: 'image/jpeg',
      tempfile: File.new("#{cwd}/../../../spec/fixtures/photo2.jpg")
    })
  end

  RAW_MSG = "Received: from mail-wg0-f41.google.com (mail-wg0-f41.google.com [74.125.82.41])\n\tby ip-10-249-27-209 (Postfix) with ESMTPS id 45C7FE1C0D9\n\tfor <token@reply.example.com>; Tue,  9 Apr 2013 19:55:20 +0000 (UTC)\nReceived: by mail-wg0-f41.google.com with SMTP id y10so5288278wgg.4\n        for <token@reply.example.com>; Tue, 09 Apr 2013 12:55:18 -0700 (PDT)\nDKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;\n        d=familink.cl; s=google;\n        h=x-received:mime-version:sender:x-originating-ip:in-reply-to\n         :references:from:date:x-google-sender-auth:message-id:subject:to:cc\n         :content-type;\n        bh=d8eE6y8Ps7erFwaIUp5w/f7Fwr86M88pDblOvPacicY=;\n        b=W1gE1es9IhgkC1T4IaivCT/FA7SCc7oSB53zJItVsPMYaMSSdOTuAfmZKUn0kCuhoN\n         EzT/UakpQ87tQAa3+dYzEcBRevmLOPVIazYOZDam9lZ0QCe5ijQS23M4RXu7DIzTGqnO\n         XG8xmUDdVf+ZfTfU0OXjEE5lJ1FqM4o/agzHE=\nDKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;\n        d=familink.us; s=google;\n        h=x-received:mime-version:sender:x-originating-ip:in-reply-to\n         :references:from:date:x-google-sender-auth:message-id:subject:to:cc\n         :content-type;\n        bh=d8eE6y8Ps7erFwaIUp5w/f7Fwr86M88pDblOvPacicY=;\n        b=ekd/aa2TJ+eWPpWmYxgW5NQGH4Sb90SNzqgF3pgQSeV1mGbzGX5CkDNZMjSqYOLbHW\n         Mrqs6WRYQrksIw+WmDNVkf8Cel0lmqgNjrDseeKrfBogMC6qrBosSE5WAFB5rjCkLm3M\n         ZbhJTDIwXdQyYa8b82QTUSqCOJfUeBc4pSEO0=\nX-Google-DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;\n        d=google.com; s=20120113;\n        h=x-received:mime-version:sender:x-originating-ip:in-reply-to\n         :references:from:date:x-google-sender-auth:message-id:subject:to:cc\n         :content-type:x-gm-message-state;\n        bh=d8eE6y8Ps7erFwaIUp5w/f7Fwr86M88pDblOvPacicY=;\n        b=Ikz3/TxRZau+fmQUdWmpWPnUyvRMaUrq1S1EkrH198oCKKW1sq8k5XepYeRkSRUV+3\n         zZefH6ir+hC84yE4YKMPqRJhE6Mylhst5BW1OMwOrv0AZA5WWDUjhZ5UM1+UsBauo3RX\n         CZ0QYqJI9aY/KrIRzNEjuUAdJiACXSgDWijaW5XVFt3swNiLZgqsjM8mOCSoH1I+lgx9\n         y/RI+FKCT3xMStlgGJf0eHXW+nSjdfV8sp5+lhuSNL25cLvspOP5Z7X0K3WYeBkKbT0s\n         WEz/O3NMzbJWvcDi9O8DsUO9b+oRzzi39SnwiLCMyiaM/UMfhq4gfbrxXqPjHYZYeHYK\n         a9tg==\nX-Received: by 10.180.105.99 with SMTP id gl3mr22144866wib.22.1365537318452;\n Tue, 09 Apr 2013 12:55:18 -0700 (PDT)\nMIME-Version: 1.0\nSender: hernan@example.com\nReceived: by 10.216.102.1 with HTTP; Tue, 9 Apr 2013 12:54:58 -0700 (PDT)\nX-Originating-IP: [98.234.86.149]\nIn-Reply-To: <hernan@example.com>\nReferences: <hernan@example.com>\nFrom: =?UTF-8?Q?Hern=C3=A1n_Schmidt?= <hernan@example.com>\nDate: Tue, 9 Apr 2013 12:54:58 -0700\nX-Google-Sender-Auth: t1Tl5cYdgdueAip4mbo91Er354g\nMessage-ID: <some-id@mail.gmail.com>\nSubject: Test\nTo: token@reply.example.com\nContent-Type: multipart/alternative; boundary=f46d04426d76cb545d04d9f2ee16\nX-Gm-Message-State: ALoCoQmFQOMiNYMhMVU0gSKQDMGB8ZiJIcvtdOUhIxeQUPv7jm+Lcc+p1Qx3+6f5mYrhQhCZV1ny\n\n--f46d04426d76cb545d04d9f2ee16\nContent-Type: text/plain; charset=UTF-8\nContent-Transfer-Encoding: quoted-printable\n\nTest\n>\n\n--f46d04426d76cb545d04d9f2ee16\nContent-Type: text/html; charset=UTF-8\nContent-Transfer-Encoding: quoted-printable\n\nTest\n\n--f46d04426d76cb545d04d9f2ee16--"
end
