requires 'perl', '5.008001';
requires 'Otogiri';
requires 'Otogiri::Plugin';
requires 'Otogiri::Plugin::BulkInsert';
requires 'Otogiri::Plugin::TableInfo';
requires 'Bloom::Filter';
requires 'Module::Load';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'File::Temp';
    requires 'HTTP::Request::Common';
};

